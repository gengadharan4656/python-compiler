package com.pydroid.app.engine

import android.content.Context
import android.util.Log
import com.chaquo.python.Python
import com.chaquo.python.PyException
import kotlinx.coroutines.withTimeout
import java.io.File

class PythonEngineManager(private val context: Context) {

    companion object {
        private const val TAG = "PythonEngineManager"
        private val AVAILABLE_PACKAGES = listOf(
            "requests", "urllib3", "pillow", "numpy", "sympy",
            "pandas", "python-dateutil", "rich", "faker", "colorama", "pydantic"
        )
    }

    private var initialized = false
    @Volatile private var shouldStop = false

    fun initialize() {
        if (initialized) return
        Python.getInstance().getModule("sys")
        initialized = true
        Log.d(TAG, "PythonEngineManager initialized")
    }

    suspend fun runCode(code: String, projectId: String, stdinInput: String,
                        timeoutSeconds: Int, onOutput: (String) -> Unit): Map<String, Any> {
        shouldStop = false
        val startTime = System.currentTimeMillis()
        return try {
            withTimeout(timeoutSeconds * 1000L) {
                executeCode(code, projectId, stdinInput, onOutput)
            }
        } catch (e: kotlinx.coroutines.TimeoutCancellationException) {
            mapOf("status" to "timeout", "stdout" to "",
                "stderr" to "TimeoutError: Execution exceeded ${timeoutSeconds} seconds",
                "executionTimeMs" to (System.currentTimeMillis() - startTime).toInt())
        }
    }

    private fun executeCode(code: String, projectId: String, stdinInput: String, onOutput: (String) -> Unit): Map<String, Any> {
        val startTime = System.currentTimeMillis()
        return try {
            val py = Python.getInstance()
            val runner = py.getModule("runner")
            val codeFile = writeTempCode(code, projectId)
            val result = runner.callAttr("run_file", codeFile.absolutePath, stdinInput, projectId)
            val resultMap = result.asMap()
            val elapsed = System.currentTimeMillis() - startTime

            val stdoutKey = py.builtins.callAttr("str", "stdout")
            val stderrKey = py.builtins.callAttr("str", "stderr")
            val statusKey = py.builtins.callAttr("str", "status")

            val stdout = resultMap[stdoutKey]?.toString() ?: ""
            val stderr = resultMap[stderrKey]?.toString() ?: ""
            val status = resultMap[statusKey]?.toString() ?: "error"

            if (stdout.isNotEmpty()) onOutput(stdout)
            if (stderr.isNotEmpty()) onOutput(stderr)

            mapOf("status" to status, "stdout" to stdout, "stderr" to stderr, "executionTimeMs" to elapsed.toInt())
        } catch (e: PyException) {
            val elapsed = System.currentTimeMillis() - startTime
            val errorMsg = e.message ?: "Python error"
            onOutput(errorMsg)
            mapOf("status" to "error", "stdout" to "", "stderr" to errorMsg, "executionTimeMs" to elapsed.toInt())
        } catch (e: Exception) {
            val elapsed = System.currentTimeMillis() - startTime
            mapOf("status" to "error", "stdout" to "", "stderr" to (e.message ?: "Unknown error"), "executionTimeMs" to elapsed.toInt())
        }
    }

    private fun writeTempCode(code: String, projectId: String): File {
        val tempDir = File(context.filesDir, "temp/$projectId")
        tempDir.mkdirs()
        val codeFile = File(tempDir, "exec_main.py")
        codeFile.writeText(code)
        return codeFile
    }

    fun stopExecution() {
        shouldStop = true
        try { Python.getInstance().getModule("runner").callAttr("stop_execution") } catch (e: Exception) { }
    }

    fun getAvailablePackages(): List<String> = AVAILABLE_PACKAGES
}
