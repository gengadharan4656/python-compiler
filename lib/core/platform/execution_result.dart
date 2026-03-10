enum ExecutionStatus { success, error, timeout, interrupted, running }

class ExecutionResult {
  final ExecutionStatus status;
  final String stdout;
  final String stderr;
  final int executionTimeMs;

  const ExecutionResult({
    required this.status,
    required this.stdout,
    required this.stderr,
    required this.executionTimeMs,
  });

  factory ExecutionResult.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'error';
    return ExecutionResult(
      status: _parseStatus(statusStr),
      stdout: map['stdout'] as String? ?? '',
      stderr: map['stderr'] as String? ?? '',
      executionTimeMs: map['executionTimeMs'] as int? ?? 0,
    );
  }

  static ExecutionStatus _parseStatus(String s) {
    switch (s) {
      case 'success': return ExecutionStatus.success;
      case 'timeout': return ExecutionStatus.timeout;
      case 'interrupted': return ExecutionStatus.interrupted;
      default: return ExecutionStatus.error;
    }
  }

  bool get isSuccess => status == ExecutionStatus.success;
}
