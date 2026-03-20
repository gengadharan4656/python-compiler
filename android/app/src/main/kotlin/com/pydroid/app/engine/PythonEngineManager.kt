package com.pydroid.app.engine

import android.content.Context
import android.util.Log
import com.chaquo.python.PyException
import com.chaquo.python.Python
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeout
import java.io.File

class PythonEngineManager(private val context: Context) {

    companion object {
        private const val TAG = "PythonEngineManager"
        private val AVAILABLE_PACKAGES = listOf(
            "requests",
            "urllib3",
            "pillow",
            "numpy",
            "sympy",
            "pandas",
            "matplotlib",
            "python-dateutil",
            "rich",
            "faker",
            "colorama",
            "pydantic",
        )
    }

    private var initialized = false

    fun initialize() {
        if (initialized) return
        Python.getInstance().getModule("sys")
        initialized = true
        Log.d(TAG, "PythonEngineManager initialized")
    }

    suspend fun runCode(
        code: String,
        projectId: String,
        projectPath: String,
        entryFileName: String,
        timeoutSeconds: Int,
        onOutputEvent: (Map<String, Any>) -> Unit,
    ): Map<String, Any> {
        val startTime = System.currentTimeMillis()
        return try {
            withTimeout(timeoutSeconds * 1000L) {
                executeCode(code, projectId, projectPath, entryFileName, onOutputEvent)
            }
        } catch (e: kotlinx.coroutines.TimeoutCancellationException) {
            stopExecution()
            mapOf(
                "status" to "timeout",
                "stdout" to "",
                "stderr" to "TimeoutError: Execution exceeded ${timeoutSeconds} seconds",
                "executionTimeMs" to (System.currentTimeMillis() - startTime).toInt(),
            )
        }
    }

    private suspend fun executeCode(
        code: String,
        projectId: String,
        projectPath: String,
        entryFileName: String,
        onOutputEvent: (Map<String, Any>) -> Unit,
    ): Map<String, Any> {
        val startTime = System.currentTimeMillis()
        return try {
            val py = Python.getInstance()
            val runner = py.getModule("runner")
            val entryFile = resolveEntryFile(code, projectId, projectPath, entryFileName)
            val packagesDir = getPackagesDir()

            runner.callAttr(
                "run_file",
                entryFile.absolutePath,
                projectId,
                projectPath,
                packagesDir.absolutePath,
            )

            while (true) {
                val rawEvents = runner.callAttr("poll_events").asList()
                for (rawEvent in rawEvents) {
                    val mappedEvent = mutableMapOf<String, Any>()
                    for ((key, value) in rawEvent.asMap()) {
                        mappedEvent[key.toString()] = value?.toString() ?: ""
                    }
                    onOutputEvent(mappedEvent)
                }

                val snapshot = runner.callAttr("get_session_result").asMap()
                val normalized = snapshot.mapKeys { it.key.toString() }
                val done = normalized["done"]?.toString()?.toBoolean() ?: false
                if (done) {
                    val stdout = normalized["stdout"]?.toString() ?: ""
                    val stderr = normalized["stderr"]?.toString() ?: ""
                    val status = normalized["status"]?.toString() ?: "error"
                    return mapOf(
                        "status" to status,
                        "stdout" to stdout,
                        "stderr" to stderr,
                        "executionTimeMs" to ((normalized["executionTimeMs"]?.toString()?.toIntOrNull())
                            ?: (System.currentTimeMillis() - startTime).toInt()),
                    )
                }
                delay(16)
            }
        } catch (e: PyException) {
            val elapsed = System.currentTimeMillis() - startTime
            val errorMsg = e.message ?: "Python error"
            onOutputEvent(mapOf("type" to "stderr", "text" to errorMsg))
            mapOf(
                "status" to "error",
                "stdout" to "",
                "stderr" to errorMsg,
                "executionTimeMs" to elapsed.toInt(),
            )
        } catch (e: Exception) {
            val elapsed = System.currentTimeMillis() - startTime
            mapOf(
                "status" to "error",
                "stdout" to "",
                "stderr" to (e.message ?: "Unknown error"),
                "executionTimeMs" to elapsed.toInt(),
            )
        }
    }

    private fun resolveEntryFile(code: String, projectId: String, projectPath: String, entryFileName: String): File {
        if (projectPath.isNotBlank()) {
            val candidate = File(projectPath, entryFileName)
            if (candidate.exists()) return candidate
        }

        val tempDir = File(context.filesDir, "temp/$projectId")
        tempDir.mkdirs()
        val codeFile = File(tempDir, "exec_main.py")
        codeFile.writeText(code)
        return codeFile
    }

    private fun getPackagesDir(): File {
        val dir = File(context.filesDir, "python_packages")
        dir.mkdirs()
        return dir
    }

    fun installPackage(packageName: String): Map<String, Any> {
        if (packageName.isBlank()) {
            return mapOf("success" to false, "message" to "Package name is required")
        }

        return try {
            val py = Python.getInstance()
            val module = py.getModule("package_registry")
            val result = module.callAttr("install_package", packageName, getPackagesDir().absolutePath)
            val asMap = result.asMap()
            val successKey = py.builtins.callAttr("str", "success")
            val messageKey = py.builtins.callAttr("str", "message")
            mapOf(
                "success" to (asMap[successKey]?.toString()?.toBoolean() ?: false),
                "message" to (asMap[messageKey]?.toString() ?: "Installation finished"),
            )
        } catch (e: Exception) {
            mapOf("success" to false, "message" to (e.message ?: "Install failed"))
        }
    }

    fun submitInput(line: String): Boolean {
        return try {
            Python.getInstance().getModule("runner").callAttr("submit_input", line)
            true
        } catch (_: Exception) {
            false
        }
    }

    fun stopExecution() {
        try {
            Python.getInstance().getModule("runner").callAttr("stop_execution")
        } catch (_: Exception) {
        }
    }

    fun getAvailablePackages(): List<String> = AVAILABLE_PACKAGES
}
