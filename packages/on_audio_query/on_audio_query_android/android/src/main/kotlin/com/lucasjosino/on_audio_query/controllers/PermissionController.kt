package com.lucasjosino.on_audio_query.controllers

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.lucasjosino.on_audio_query.interfaces.PermissionManagerInterface
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class PermissionController(
    private var retryRequest: Boolean = false
) : PermissionManagerInterface, PluginRegistry.RequestPermissionsResultListener {

    //
    private lateinit var activity: Activity
    private lateinit var result: MethodChannel.Result

    //
    private val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        arrayOf(
            Manifest.permission.READ_MEDIA_AUDIO
        )
    } else {
        arrayOf(
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        )
    }

    private val requestCode: Int = 88560

    override fun permissionStatus(context: Context): Boolean = permissions.all {
        // After "leaving" this class, context will be null so, we need this context argument to
        // call the [checkSelfPermission].
        return ContextCompat.checkSelfPermission(
            context,
            it
        ) == PackageManager.PERMISSION_GRANTED
    }

    override fun requestPermission(activity: Activity, result: MethodChannel.Result) {
        this.activity = activity
        this.result = result
        ActivityCompat.requestPermissions(activity, permissions, requestCode)
    }

    // Second requestPermission, this one with the option "Never Ask Again".
    override fun retryRequestPermission() {
        if (ActivityCompat.shouldShowRequestPermissionRationale(activity, permissions[0])
            || ActivityCompat.shouldShowRequestPermissionRationale(activity, permissions[1])
        ) {
            retryRequest = false
            if (this::activity.isInitialized && this::result.isInitialized) {
                requestPermission(activity, result)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        // When [pResult] is not initialized the permission request did not originate from the
        // [on_audio_query] plugin, so return [false] to indicate the [on_audio_query] plugin is not
        // handling the request result and Android should continue executing other registered handlers.
        if (!this::result.isInitialized) return false

        // When the incoming request code doesn't match the request codes defined by the on_audio_query
        // plugin return [false] to indicate the [on_audio_query] plugin is not handling the request
        // result and Android should continue executing other registered handlers.
        if (requestCode != requestCode) return false

        // Check permission
        val isPermissionGranted = (grantResults.isNotEmpty()
                && grantResults[0] == PackageManager.PERMISSION_GRANTED)

        // After all checks, we can handle the permission request.
        when {
            isPermissionGranted -> result.success(true)
            retryRequest -> retryRequestPermission()
            else -> result.success(false)
        }

        // Return [true] here to indicate that the [on_audio_query] plugin handled the permission request
        // result and Android should not continue executing other registered handlers.
        return true
    }
}
