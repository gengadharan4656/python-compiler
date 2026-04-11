import 'dart:collection';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/platform/execution_result.dart';
import '../../../core/platform/python_channel.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../projects/presentation/project_provider.dart';
import '../../settings/presentation/settings_provider.dart';

enum ConsoleEntryType { stdout, stderr, system, prompt, input }

class ConsoleEntry {
  final String text;
  final ConsoleEntryType type;

  const ConsoleEntry({required this.text, required this.type});
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final bool isWaitingForInput;
  final ExecutionResult? result;
  final List<ConsoleEntry> outputEntries;
  final String activePrompt;
  final String terminalInput;

  const ExecutionState({
    this.isRunning = false,
    this.isWaitingForInput = false,
    this.result,
    this.outputEntries = const [],
    this.activePrompt = '',
    this.terminalInput = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    bool? isWaitingForInput,
    ExecutionResult? result,
    List<ConsoleEntry>? outputEntries,
    String? activePrompt,
    String? terminalInput,
    bool clearResult = false,
  }) => ExecutionState(
    isRunning: isRunning ?? this.isRunning,
    isWaitingForInput: isWaitingForInput ?? this.isWaitingForInput,
    result: clearResult ? null : (result ?? this.result),
    outputEntries: outputEntries ?? this.outputEntries,
    activePrompt: activePrompt ?? this.activePrompt,
    terminalInput: terminalInput ?? this.terminalInput,
  );
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref _ref;
  late final StreamSubscription<Map<String, dynamic>> _outputSubscription;
  final Queue<String> _queuedInputs = Queue<String>();
  final List<ConsoleEntry> _pendingEntries = [];
  Timer? _flushTimer;
  int _flushVersion = 0;

  ExecutionNotifier(this._ref) : super(const ExecutionState()) {
    _outputSubscription = PythonChannel.instance.outputStream.listen(_handleEvent);
  }

  void setTerminalInput(String value) {
    state = state.copyWith(terminalInput: value);
  }

  Future<void> runCode(String code, {required String entryFileName}) async {
    final project = _ref.read(currentProjectProvider);
    if (project == null) return;
    final settings = _ref.read(settingsProvider);
    final repo = _ref.read(projectRepositoryProvider);
    final projectPath = await repo.getProjectPath(project.id);

    state = ExecutionState(
      isRunning: true,
      isWaitingForInput: false,
      activePrompt: '',
      terminalInput: '',
      outputEntries: [
        ConsoleEntry(text: '\$ python $entryFileName\n', type: ConsoleEntryType.system),
      ],
    );

    try {
      final result = await PythonChannel.instance.runCode(
        code: code,
        projectId: project.id,
        timeoutSeconds: settings.executionTimeoutSeconds,
        projectPath: projectPath,
        entryFileName: entryFileName,
      );

      final statusLine = switch (result.status) {
        ExecutionStatus.success => '\n[exit 0 • ${result.executionTimeMs}ms]\n',
        ExecutionStatus.timeout => '\n[timeout after ${settings.executionTimeoutSeconds}s]\n',
        ExecutionStatus.interrupted => '\n[stopped]\n',
        _ => '\n[exit 1]\n',
      };

      _appendEntry(ConsoleEntry(text: statusLine, type: ConsoleEntryType.system));
      state = state.copyWith(
        isRunning: false,
        isWaitingForInput: false,
        activePrompt: '',
        result: result,
        terminalInput: '',
      );
    } catch (e) {
      _appendEntry(ConsoleEntry(text: 'Error: $e', type: ConsoleEntryType.stderr));
      state = state.copyWith(
        isRunning: false,
        isWaitingForInput: false,
        activePrompt: '',
        terminalInput: '',
        clearResult: true,
      );
    }
  }

  Future<void> submitTerminalInput() async {
    final line = state.terminalInput;
    if (!state.isRunning) return;

    if (!state.isWaitingForInput) {
      _queuedInputs.add(line);
      state = state.copyWith(terminalInput: '');
      return;
    }

    await _submitInputLine(line, prompt: state.activePrompt);
  }

  Future<void> _submitInputLine(String line, {required String prompt}) async {
    final transcriptLine = '$prompt$line\n';
    _appendEntry(ConsoleEntry(text: transcriptLine, type: ConsoleEntryType.input));
    state = state.copyWith(
      terminalInput: '',
      isWaitingForInput: false,
      activePrompt: '',
    );

    try {
      await PythonChannel.instance.submitInput(line);
    } catch (e) {
      _appendEntry(ConsoleEntry(text: 'Input error: $e\n', type: ConsoleEntryType.stderr));
    }
  }

  Future<void> stopCode() async {
    await PythonChannel.instance.stopCode();
    state = state.copyWith(
      isRunning: false,
      isWaitingForInput: false,
      activePrompt: '',
      terminalInput: '',
    );
  }

  void clearConsole() => state = state.copyWith(outputEntries: [], activePrompt: '', terminalInput: '', clearResult: true);

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? 'stdout';
    final text = event['text']?.toString() ?? '';

    switch (type) {
      case 'stdout':
        if (text.isNotEmpty) {
          _appendEntry(ConsoleEntry(text: text, type: ConsoleEntryType.stdout));
        }
        break;
      case 'stderr':
        if (text.isNotEmpty) {
          _appendEntry(ConsoleEntry(text: text, type: ConsoleEntryType.stderr));
        }
        break;
      case 'input_request':
        final prompt = event['prompt']?.toString() ?? '';
        state = state.copyWith(
          isWaitingForInput: true,
          activePrompt: prompt,
          terminalInput: '',
        );
        if (_queuedInputs.isNotEmpty) {
          final queuedLine = _queuedInputs.removeFirst();
          unawaited(_submitInputLine(queuedLine, prompt: prompt));
        }
        break;
      case 'system':
        if (text.isNotEmpty) {
          _appendEntry(ConsoleEntry(text: text, type: ConsoleEntryType.system));
        }
        break;
      default:
        break;
    }
  }

  void _appendEntry(ConsoleEntry entry) {
    _pendingEntries.add(entry);
    _flushTimer ??= Timer(const Duration(milliseconds: 16), () {
      unawaited(_flushPendingEntries());
    });
  }

  Future<void> _flushPendingEntries() async {
    _flushTimer = null;
    if (_pendingEntries.isEmpty) return;

    final snapshot = List<ConsoleEntry>.from(_pendingEntries);
    _pendingEntries.clear();
    final baseEntries = List<ConsoleEntry>.from(state.outputEntries);
    final version = ++_flushVersion;

    final entries = _mergeOutputEntries(baseEntries, snapshot, AppConstants.maxOutputLines);

    if (version != _flushVersion) {
      if (_pendingEntries.isNotEmpty) {
        _flushTimer ??= Timer(const Duration(milliseconds: 16), () {
          unawaited(_flushPendingEntries());
        });
      }
      return;
    }

    state = state.copyWith(outputEntries: entries);
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    _outputSubscription.cancel();
    super.dispose();
  }
}

List<ConsoleEntry> _mergeOutputEntries(
  List<ConsoleEntry> current,
  List<ConsoleEntry> pending,
  int maxLines,
) {
  final merged = [...current, ...pending];
  if (merged.length > maxLines) {
    merged.removeRange(0, merged.length - maxLines);
  }
  return merged;
}
