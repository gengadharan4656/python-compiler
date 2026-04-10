import 'dart:isolate';

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
    required String projectPath,
    required String entryFileName,
    int timeoutSeconds = AppConstants.defaultTimeoutSeconds,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>(AppConstants.methodRun, {
        'code': code,
        'projectId': projectId,
        'projectPath': projectPath,
        'entryFileName': entryFileName,
        'timeoutSeconds': timeoutSeconds,
      });
      final normalized = Map<String, dynamic>.from(result ?? {});
      return Isolate.run(() => ExecutionResult.fromMap(normalized));
    } on PlatformException catch (e) {
      return ExecutionResult(
        status: ExecutionStatus.error,
        stdout: '',
        stderr: e.message ?? 'Unknown error',
        executionTimeMs: 0,
      );
    }
  }

  Future<void> submitInput(String line) async {
    try {
      await _channel.invokeMethod(AppConstants.methodSubmitInput, {'input': line});
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Failed to send input');
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

  Future<Map<String, dynamic>> installPackage(String packageName) async {
    try {
      final result = await _channel.invokeMethod<Map>(
        AppConstants.methodInstallPackage,
        {'package': packageName},
      );
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      return {'success': false, 'message': e.message ?? 'Installation failed'};
    }
  }

  Stream<Map<String, dynamic>> get outputStream => _outputChannel
      .receiveBroadcastStream()
      .map((event) => Map<String, dynamic>.from((event as Map?) ?? const {}));
}
