package com.pydroid.app.sandbox

import android.content.Context
import java.io.File

class ExecutionSandboxManager(private val context: Context) {
    fun createProjectSandbox(projectId: String): File {
        val dir = File(context.filesDir, "projects/$projectId")
        dir.mkdirs()
        return dir
    }
    fun getTempDir(projectId: String): File {
        val dir = File(context.filesDir, "temp/$projectId")
        dir.mkdirs()
        return dir
    }
    fun isPathAllowed(path: String, projectId: String): Boolean {
        val projectPath = File(context.filesDir, "projects/$projectId").absolutePath
        val tempPath = File(context.filesDir, "temp/$projectId").absolutePath
        return path.startsWith(projectPath) || path.startsWith(tempPath)
    }
}
