import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/execution_result.dart';
import '../../../core/platform/python_channel.dart';
import '../../projects/presentation/project_provider.dart';
import '../../settings/presentation/settings_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final ExecutionResult? result;
  final List<String> outputLines;

  const ExecutionState({this.isRunning = false, this.result, this.outputLines = const []});

  ExecutionState copyWith({bool? isRunning, ExecutionResult? result, List<String>? outputLines}) =>
    ExecutionState(isRunning: isRunning ?? this.isRunning, result: result ?? this.result,
      outputLines: outputLines ?? this.outputLines);
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref _ref;
  ExecutionNotifier(this._ref) : super(const ExecutionState());

  Future<void> runCode(String code) async {
    final project = _ref.read(currentProjectProvider);
    if (project == null) return;
    final settings = _ref.read(settingsProvider);

    state = ExecutionState(isRunning: true, outputLines: ['▶ Running ${project.name}...\n']);

    try {
      final result = await PythonChannel.instance.runCode(
        code: code, projectId: project.id,
        timeoutSeconds: settings.executionTimeoutSeconds,
      );

      final lines = <String>[];
      if (result.stdout.isNotEmpty) lines.add(result.stdout);
      if (result.stderr.isNotEmpty) lines.add(result.stderr);

      String statusLine;
      switch (result.status) {
        case ExecutionStatus.success:
          statusLine = '\n✓ Completed in ${result.executionTimeMs}ms'; break;
        case ExecutionStatus.timeout:
          statusLine = '\n⏱ Execution timed out after ${settings.executionTimeoutSeconds}s'; break;
        case ExecutionStatus.interrupted:
          statusLine = '\n⚠ Execution stopped'; break;
        default:
          statusLine = '\n✗ Error';
      }
      lines.add(statusLine);
      state = ExecutionState(isRunning: false, result: result, outputLines: lines);
    } catch (e) {
      state = ExecutionState(isRunning: false, outputLines: ['Error: $e']);
    }
  }

  Future<void> stopCode() async {
    await PythonChannel.instance.stopCode();
    state = state.copyWith(isRunning: false,
      outputLines: [...state.outputLines, '\n⚠ Execution interrupted']);
  }

  void clearConsole() => state = state.copyWith(outputLines: []);
}
