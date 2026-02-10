package com.gokadzev.musify

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
  private val channelName = "musify/audio_permissions"
  private val permissionRequestCode = 1201
  private var pendingResult: MethodChannel.Result? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    // Aligns the Flutter view vertically with the window.
    WindowCompat.setDecorFitsSystemWindows(getWindow(), false)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      // Disable the Android splash screen fade out animation to avoid
      // a flicker before the similar frame is drawn in Flutter.
      splashScreen.setOnExitAnimationListener { splashScreenView -> splashScreenView.remove() }
    }

    super.onCreate(savedInstanceState)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "hasAudioPermission" -> result.success(hasAudioPermission())
          "requestAudioPermission" -> handlePermissionRequest(result)
          else -> result.notImplemented()
        }
      }
  }

  private fun handlePermissionRequest(result: MethodChannel.Result) {
    if (hasAudioPermission()) {
      result.success(true)
      return
    }
    if (pendingResult != null) {
      result.error("PENDING", "Permission request already running", null)
      return
    }
    pendingResult = result
    ActivityCompat.requestPermissions(
      this,
      arrayOf(requiredAudioPermission()),
      permissionRequestCode
    )
  }

  private fun hasAudioPermission(): Boolean {
    return ContextCompat.checkSelfPermission(
      this,
      requiredAudioPermission()
    ) == PackageManager.PERMISSION_GRANTED
  }

  private fun requiredAudioPermission(): String {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      Manifest.permission.READ_MEDIA_AUDIO
    } else {
      Manifest.permission.READ_EXTERNAL_STORAGE
    }
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray,
  ) {
    if (requestCode == permissionRequestCode) {
      val granted = grantResults.isNotEmpty() &&
        grantResults[0] == PackageManager.PERMISSION_GRANTED
      pendingResult?.success(granted)
      pendingResult = null
      return
    }
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
  }
}
