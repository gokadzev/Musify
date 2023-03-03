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

import android.app.Activity
import android.content.Context
import android.media.MediaScannerConnection
import android.os.Build
import androidx.annotation.NonNull
import com.lucasjosino.on_audio_query.controllers.PermissionController
import com.lucasjosino.on_audio_query.controllers.QueryController
import com.lucasjosino.on_audio_query.methods.observers.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** OnAudioQueryPlugin Central */
class OnAudioQueryPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        // Get the current class name.
        private val TAG: String = this::class.java.name

        // Method channel name.
        private const val CHANNEL_NAME = "com.lucasjosino.on_audio_query"

        // Event channels name.
        private const val AUDIOS_OBS_CHANNEL_NAME = "$CHANNEL_NAME/audios_observer"
        private const val ALBUMS_OBS_CHANNEL_NAME = "$CHANNEL_NAME/albums_observer"
        private const val PLAYLISTS_OBS_CHANNEL_NAME = "$CHANNEL_NAME/playlists_observer"
        private const val ARTISTS_OBS_CHANNEL_NAME = "$CHANNEL_NAME/artists_observer"
        private const val GENRES_OBS_CHANNEL_NAME = "$CHANNEL_NAME/genres_observer"
    }

    // Dart <-> Kotlin communication
    private lateinit var channel: MethodChannel

    //
    private lateinit var context: Context
    private lateinit var queryController: QueryController
    private lateinit var permissionController: PermissionController

    // Main parameters
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null

    // Observers
    private var audiosObserver: AudiosObserver? = null
    private var albumsObserver: AlbumsObserver? = null
    private var playlistsObserver: PlaylistsObserver? = null
    private var artistsObserver: ArtistsObserver? = null
    private var genresObserver: GenresObserver? = null

    // Dart <-> Kotlin communication
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // Define the [context]
        context = flutterPluginBinding.applicationContext

        // Setup the method channel communication.
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        // Setup all event channel communication.
        setUpEventChannel(flutterPluginBinding.binaryMessenger)
    }

    // Methods will always follow the same route:
    // Receive method -> check permission -> controller -> do what's needed -> return to dart
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        // Setup the [QueryController].
        this.queryController = QueryController(context, call, result)

        // Both [activity] and [binding] are from [onAttachedToActivity].
        // If one of them are null. Something is really wrong.
        if (activity == null || binding == null) {
            result.error(
                "$TAG::onMethodCall",
                "The [activity] or [binding] parameter is null!",
                null
            )
        }

        // If user deny permission request a pop up will immediately show up.
        // If [retryRequest] is null, the message will only show after calling the method again.
        val retryRequest = call.argument<Boolean>("retryRequest") ?: false

        // Setup the [PermissionController]
        permissionController = PermissionController(retryRequest)

        // Detect the method.
        when (call.method) {
            // Permissions
            "permissionsStatus" -> result.success(permissionController.permissionStatus(context))
            "permissionsRequest" -> {
                // Add to controller the ability to listen the request result.
                binding!!.addRequestPermissionsResultListener(permissionController)

                // Request the permission.
                permissionController.requestPermission(activity!!, result)
            }

            // Device information
            "queryDeviceInfo" -> {
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
            "scan" -> {
                // TODO: Add option to scan multiple paths.
                val sPath: String = call.argument<String>("path")!!

                // Check if the given file is empty.
                if (sPath.isEmpty()) result.success(false)

                // Scan and return
                MediaScannerConnection.scanFile(
                    context,
                    arrayOf(sPath),
                    null
                ) { _, _ ->
                    result.success(true)
                }
            }

            "observersStatus" -> {
                result.success(
                    hashMapOf(
                        "audios_observer" to (audiosObserver?.isRunning ?: false),
                        "albums_observer" to (albumsObserver?.isRunning ?: false),
                        "artists_observer" to (artistsObserver?.isRunning ?: false),
                        "playlists_observer" to (playlistsObserver?.isRunning ?: false),
                        "genres_observer" to (genresObserver?.isRunning ?: false),
                    )
                )
            }

            // All others methods
            else -> queryController.call()
        }
    }

    // Dart <-> Kotlin communication
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // Attach the activity and get the [activity] and [binding].
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        // Define the activity and binding.
        this.activity = binding.activity
        this.binding = binding
    }

    //
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    // Detach all parameters.
    override fun onDetachedFromActivity() {
        // Remove the permission listener
        if (binding != null) {
            binding!!.removeRequestPermissionsResultListener(permissionController)
        }

        // Remove both [activity] and [binding].
        this.activity = null
        this.binding = null

        // Remove all event channel.
        audiosObserver?.onCancel(null)
        audiosObserver = null

        albumsObserver?.onCancel(null)
        albumsObserver = null

        playlistsObserver?.onCancel(null)
        playlistsObserver = null

        artistsObserver?.onCancel(null)
        artistsObserver = null

        genresObserver?.onCancel(null)
        genresObserver = null
    }

    //
    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    // TODO: Check if this setup consumes much memory.
    private fun setUpEventChannel(binaryMessenger: BinaryMessenger) {
        // Audios channel.
        val audiosChannel = EventChannel(binaryMessenger, AUDIOS_OBS_CHANNEL_NAME)
        audiosObserver = AudiosObserver(context)
        audiosChannel.setStreamHandler(audiosObserver)

        // Albums channel.
        val albumsChannel = EventChannel(binaryMessenger, ALBUMS_OBS_CHANNEL_NAME)
        albumsObserver = AlbumsObserver(context)
        albumsChannel.setStreamHandler(albumsObserver)

        // Playlists channel.
        val playlistsChannel = EventChannel(binaryMessenger, PLAYLISTS_OBS_CHANNEL_NAME)
        playlistsObserver = PlaylistsObserver(context)
        playlistsChannel.setStreamHandler(playlistsObserver)

        // Artists channel.
        val artistsChannel = EventChannel(binaryMessenger, ARTISTS_OBS_CHANNEL_NAME)
        artistsObserver = ArtistsObserver(context)
        artistsChannel.setStreamHandler(artistsObserver)

        // Genres channel.
        val genresChannel = EventChannel(binaryMessenger, GENRES_OBS_CHANNEL_NAME)
        genresObserver = GenresObserver(context)
        genresChannel.setStreamHandler(genresObserver)
    }
}
