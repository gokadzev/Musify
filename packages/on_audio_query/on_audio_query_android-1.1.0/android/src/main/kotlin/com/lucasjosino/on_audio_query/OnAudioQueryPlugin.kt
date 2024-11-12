/*
=============
Author: Lucas Josino
Github: https://github.com/LucJosin
Website: https://www.lucasjosino.com/
=============
Plugin/Id: on_audio_query#0
Homepage: https://github.com/LucJosin/on_audio_query
Pub: https://pub.dev/packages/on_audio_query
License: https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/LICENSE
Copyright: © 2021, Lucas Josino. All rights reserved.
=============
*/

package com.lucasjosino.on_audio_query

import android.media.MediaScannerConnection
import android.os.Build
import com.lucasjosino.on_audio_query.consts.Method
import com.lucasjosino.on_audio_query.controllers.MethodController
import com.lucasjosino.on_audio_query.controllers.PermissionController
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class OnAudioQueryPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    init {
        // Set default logging level
        Log.setLogLevel(Log.WARN)
    }

    companion object {
        // Get the current class name.
        private const val TAG: String = "OnAudioQueryPlugin"

        // Method channel name.
        private const val CHANNEL_NAME = "com.lucasjosino.on_audio_query"
    }

    private var permissionController = PermissionController()
    private var methodController = MethodController()

    private var binding: ActivityPluginBinding? = null

    private lateinit var channel: MethodChannel

    // Dart <-> Kotlin communication
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "Attached to engine")

        // Setup the method channel communication.
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    // Methods will always follow the same route:
    // Receive method -> check permission -> controller -> do what's needed -> return to dart
    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "Started method call (${call.method})")

        // Init the plugin provider with current 'call' and 'result'.
        PluginProvider.setCurrentMethod(call, result)

        // If user deny permission request a pop up will immediately show up
        // If [retryRequest] is null, the message will only show when call method again
        val retryRequest = call.argument<Boolean>("retryRequest") ?: false
        permissionController.retryRequest = retryRequest

        Log.i(TAG, "Method call: ${call.method}")
        when (call.method) {
            // Permissions
            Method.PERMISSION_STATUS -> {
                val hasPermission = permissionController.permissionStatus()
                result.success(hasPermission)
            }
            Method.PERMISSION_REQUEST -> {
                permissionController.requestPermission()
            }

            // Device information
            Method.QUERY_DEVICE_INFO -> {
                result.success(
                    hashMapOf<String, Any>(
                        "device_model" to Build.MODEL,
                        "device_sys_version" to Build.VERSION.SDK_INT,
                        "device_sys_type" to "Android"
                    )
                )
            }

            // This method will scan the given path to update the 'state'.
            // When deleting a file using 'dart:io', call this method to update the file 'state'.
            Method.SCAN -> {
                val sPath: String? = call.argument<String>("path")
                val context = PluginProvider.context()

                // Check if the given file is null or empty.
                if (sPath == null || sPath.isEmpty()) {
                    Log.w(TAG, "Method 'scan' was called with null or empty 'path'")
                    result.success(false)
                }

                // Scan and return
                MediaScannerConnection.scanFile(context, arrayOf(sPath), null) { _, _ ->
                    Log.d(TAG, "Scanned file: $sPath")
                    result.success(true)
                }
            }

            // Logging
            Method.SET_LOG_CONFIG -> {
                // Log level
                Log.setLogLevel(call.argument<Int>("level")!!)

                // Define if 'warn' level will show more detailed logging.
                PluginProvider.showDetailedLog = call.argument<Boolean>("showDetailedLog")!!

                result.success(true)
            }

            // All others methods
            else -> {
                Log.d(TAG, "Checking permissions...")

                val hasPermission = permissionController.permissionStatus()
                Log.d(TAG, "Application has permissions: $hasPermission")

                if (!hasPermission) {
                    Log.w(TAG, "The application doesn't have access to the library")
                    result.error(
                        "MissingPermissions",
                        "Application doesn't have access to the library",
                        "Call the [permissionsRequest] method or install a external plugin to handle the app permission."
                    )
                }

                methodController.find()
            }
        }

        Log.d(TAG, "Ended method call (${call.method})\n ")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "Detached from engine")
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.i(TAG, "Attached to activity")

        // Init plugin provider with 'activity' and 'context'.
        PluginProvider.set(binding.activity)

        // Add to controller the permission to listen to the request result.
        this.binding = binding
        binding.addRequestPermissionsResultListener(permissionController)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.i(TAG, "Detached from engine (config changes)")
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.i(TAG, "Reattached to activity (config changes)")
        onAttachedToActivity(binding)
    }

    // Detach all parameters.
    override fun onDetachedFromActivity() {
        Log.i(TAG, "Detached from activity")

        // Remove the permission listener
        if (binding != null) {
            binding!!.removeRequestPermissionsResultListener(permissionController)
        }

        this.binding = null
        Log.i(TAG, "Removed all declared methods")
    }
}
