package com.pydroid.app.bridge

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import com.pydroid.app.engine.PythonEngineManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class PythonBridgePlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    private val engineManager = PythonEngineManager(context)
    private var outputEventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val mainHandler = Handler(Looper.getMainLooper())
    private var runningJob: Job? = null

    companion object {
        private const val TAG = "PythonBridgePlugin"
        private const val METHOD_CHANNEL = "com.pydroid.app/python_bridge"
        private const val EVENT_CHANNEL = "com.pydroid.app/python_output"

        fun register(flutterEngine: FlutterEngine, context: Context) {
            val plugin = PythonBridgePlugin(context)
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
                .setMethodCallHandler(plugin)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
                .setStreamHandler(object : EventChannel.StreamHandler {
                    override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                        plugin.outputEventSink = sink
                    }

                    override fun onCancel(args: Any?) {
                        plugin.outputEventSink = null
                    }
                })
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initPython" -> initPython(result)
            "runCode" -> runCode(call, result)
            "stopCode" -> stopCode(result)
            "submitInput" -> submitInput(call, result)
            "listPackages" -> result.success(engineManager.getAvailablePackages())
            "enablePackage" -> result.success(true)
            "disablePackage" -> result.success(true)
            "installPackage" -> installPackage(call, result)
            else -> result.notImplemented()
        }
    }

    private fun initPython(result: MethodChannel.Result) {
        try {
            if (!Python.isStarted()) Python.start(AndroidPlatform(context))
            engineManager.initialize()
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Python init failed", e)
            result.error("INIT_FAILED", e.message, null)
        }
    }

    private fun runCode(call: MethodCall, result: MethodChannel.Result) {
        val code = call.argument<String>("code") ?: ""
        val projectId = call.argument<String>("projectId") ?: "default"
        val projectPath = call.argument<String>("projectPath") ?: ""
        val entryFileName = call.argument<String>("entryFileName") ?: "main.py"
        val timeoutSeconds = call.argument<Int>("timeoutSeconds") ?: 10

        runningJob?.cancel()
        runningJob = scope.launch {
            try {
                val executionResult = engineManager.runCode(
                    code = code,
                    projectId = projectId,
                    projectPath = projectPath,
                    entryFileName = entryFileName,
                    timeoutSeconds = timeoutSeconds,
                    onOutputEvent = { event ->
                        mainHandler.post { outputEventSink?.success(event) }
                    },
                )
                withContext(Dispatchers.Main) { result.success(executionResult) }
            } catch (e: CancellationException) {
                withContext(Dispatchers.Main) {
                    result.success(
                        mapOf(
                            "status" to "interrupted",
                            "stdout" to "",
                            "stderr" to "Execution was stopped.",
                            "executionTimeMs" to 0,
                        ),
                    )
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.success(
                        mapOf(
                            "status" to "error",
                            "stdout" to "",
                            "stderr" to (e.message ?: "Unknown error"),
                            "executionTimeMs" to 0,
                        ),
                    )
                }
            }
        }
    }

    private fun submitInput(call: MethodCall, result: MethodChannel.Result) {
        val line = call.argument<String>("input") ?: ""
        result.success(engineManager.submitInput(line))
    }

    private fun installPackage(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("package") ?: ""
        scope.launch {
            try {
                val installResult = engineManager.installPackage(packageName)
                withContext(Dispatchers.Main) { result.success(installResult) }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.success(mapOf("success" to false, "message" to (e.message ?: "Install failed")))
                }
            }
        }
    }

    private fun stopCode(result: MethodChannel.Result) {
        runningJob?.cancel()
        engineManager.stopExecution()
        result.success(true)
    }
}
