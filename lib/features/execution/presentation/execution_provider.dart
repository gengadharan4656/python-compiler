import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/execution_result.dart';
import '../../../core/platform/python_channel.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../projects/presentation/project_provider.dart';
import '../../settings/presentation/settings_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final ExecutionResult? result;
  final List<String> outputLines;
  final String stdinBuffer;

  const ExecutionState({
    this.isRunning = false,
    this.result,
    this.outputLines = const [],
    this.stdinBuffer = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    ExecutionResult? result,
    List<String>? outputLines,
    String? stdinBuffer,
  }) => ExecutionState(
    isRunning: isRunning ?? this.isRunning,
    result: result ?? this.result,
    outputLines: outputLines ?? this.outputLines,
    stdinBuffer: stdinBuffer ?? this.stdinBuffer,
  );
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref _ref;
  ExecutionNotifier(this._ref) : super(const ExecutionState());

  void setStdinBuffer(String value) {
    state = state.copyWith(stdinBuffer: value);
  }

  Future<void> runCode(String code, {required String entryFileName, String? stdin}) async {
    final project = _ref.read(currentProjectProvider);
    if (project == null) return;
    final settings = _ref.read(settingsProvider);
    final repo = _ref.read(projectRepositoryProvider);
    final projectPath = await repo.getProjectPath(project.id);

    final stdinValue = stdin ?? state.stdinBuffer;

    state = ExecutionState(
      isRunning: true,
      stdinBuffer: stdinValue,
      outputLines: ['▶ Running ${project.name}...\n'],
    );

    try {
      final result = await PythonChannel.instance.runCode(
        code: code,
        projectId: project.id,
        timeoutSeconds: settings.executionTimeoutSeconds,
        stdin: stdinValue,
        projectPath: projectPath,
        entryFileName: entryFileName,
      );

      final lines = <String>[];
      if (result.stdout.isNotEmpty) lines.add(result.stdout);
      if (result.stderr.isNotEmpty) lines.add(result.stderr);

      String statusLine;
      switch (result.status) {
        case ExecutionStatus.success:
          statusLine = '\n✓ Completed in ${result.executionTimeMs}ms';
          break;
        case ExecutionStatus.timeout:
          statusLine =
              '\n⏱ Execution timed out after ${settings.executionTimeoutSeconds}s';
          break;
        case ExecutionStatus.interrupted:
          statusLine = '\n⚠ Execution stopped';
          break;
        default:
          statusLine = '\n✗ Error';
      }
      lines.add(statusLine);
      state = ExecutionState(
        isRunning: false,
        result: result,
        outputLines: lines,
        stdinBuffer: stdinValue,
      );
    } catch (e) {
      state = ExecutionState(
        isRunning: false,
        outputLines: ['Error: $e'],
        stdinBuffer: stdinValue,
      );
    }
  }

  Future<void> stopCode() async {
    await PythonChannel.instance.stopCode();
    state = state.copyWith(
      isRunning: false,
      outputLines: [...state.outputLines, '\n⚠ Execution interrupted'],
    );
  }

  void clearConsole() => state = state.copyWith(outputLines: []);
}
