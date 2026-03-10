import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import 'execution_result.dart';

class PythonChannel {
  PythonChannel._();
  static final PythonChannel instance = PythonChannel._();

  static const MethodChannel _channel = MethodChannel(AppConstants.channelName);
  static const EventChannel _outputChannel = EventChannel(AppConstants.outputEventChannel);

  bool _initialized = false;

  Future<void> initializePython() async {
    if (_initialized) return;
    try {
      await _channel.invokeMethod(AppConstants.methodInit);
      _initialized = true;
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize Python: ${e.message}');
    }
  }

  Future<ExecutionResult> runCode({
    required String code,
    required String projectId,
    String? stdin,
    int timeoutSeconds = AppConstants.defaultTimeoutSeconds,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>(AppConstants.methodRun, {
        'code': code,
        'projectId': projectId,
        'stdin': stdin ?? '',
        'timeoutSeconds': timeoutSeconds,
      });
      return ExecutionResult.fromMap(Map<String, dynamic>.from(result ?? {}));
    } on PlatformException catch (e) {
      return ExecutionResult(
        status: ExecutionStatus.error,
        stdout: '',
        stderr: e.message ?? 'Unknown error',
        executionTimeMs: 0,
      );
    }
  }

  Future<void> stopCode() async {
    try {
      await _channel.invokeMethod(AppConstants.methodStop);
    } on PlatformException {
      // ignore
    }
  }

  Future<List<String>> listAvailablePackages() async {
    try {
      final result = await _channel.invokeMethod<List>(AppConstants.methodListPackages);
      return List<String>.from(result ?? []);
    } on PlatformException {
      return [];
    }
  }

  Stream<String> get outputStream =>
      _outputChannel.receiveBroadcastStream().map((e) => e.toString());
}
