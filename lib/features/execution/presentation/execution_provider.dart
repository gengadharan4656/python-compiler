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
      outputEntries: [
        ConsoleEntry(text: '▶ Running ${project.name}...\n', type: ConsoleEntryType.system),
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
        ExecutionStatus.success => '\n✓ Completed in ${result.executionTimeMs}ms',
        ExecutionStatus.timeout => '\n⏱ Execution timed out after ${settings.executionTimeoutSeconds}s',
        ExecutionStatus.interrupted => '\n⚠ Execution stopped',
        _ => '\n✗ Error',
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
    if (!state.isRunning || !state.isWaitingForInput) return;

    _appendEntry(ConsoleEntry(text: '$line\n', type: ConsoleEntryType.input));
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
        state = state.copyWith(
          isWaitingForInput: true,
          activePrompt: event['prompt']?.toString() ?? '',
        );
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
    final entries = [...state.outputEntries, entry];
    if (entries.length > AppConstants.maxOutputLines) {
      entries.removeRange(0, entries.length - AppConstants.maxOutputLines);
    }
    state = state.copyWith(outputEntries: entries);
  }

  @override
  void dispose() {
    _outputSubscription.cancel();
    super.dispose();
  }
}
