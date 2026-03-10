package com.pydroid.app.bridge

import android.content.Context
import android.util.Log
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import com.chaquo.python.PyException
import com.pydroid.app.engine.PythonEngineManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class PythonBridgePlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    private val engineManager = PythonEngineManager(context)
    private var outputEventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
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
                    override fun onListen(args: Any?, sink: EventChannel.EventSink?) { plugin.outputEventSink = sink }
                    override fun onCancel(args: Any?) { plugin.outputEventSink = null }
                })
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initPython" -> initPython(result)
            "runCode" -> runCode(call, result)
            "stopCode" -> stopCode(result)
            "listPackages" -> result.success(engineManager.getAvailablePackages())
            "enablePackage" -> result.success(true)
            "disablePackage" -> result.success(true)
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
        val stdinInput = call.argument<String>("stdin") ?: ""
        val timeoutSeconds = call.argument<Int>("timeoutSeconds") ?: 10

        runningJob?.cancel()
        runningJob = scope.launch {
            try {
                val executionResult = engineManager.runCode(
                    code = code, projectId = projectId, stdinInput = stdinInput,
                    timeoutSeconds = timeoutSeconds,
                    onOutput = { line -> MainScope().launch { outputEventSink?.success(line) } }
                )
                withContext(Dispatchers.Main) { result.success(executionResult) }
            } catch (e: CancellationException) {
                withContext(Dispatchers.Main) {
                    result.success(mapOf("status" to "interrupted", "stdout" to "", "stderr" to "Execution was stopped.", "executionTimeMs" to 0))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.success(mapOf("status" to "error", "stdout" to "", "stderr" to (e.message ?: "Unknown error"), "executionTimeMs" to 0))
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
