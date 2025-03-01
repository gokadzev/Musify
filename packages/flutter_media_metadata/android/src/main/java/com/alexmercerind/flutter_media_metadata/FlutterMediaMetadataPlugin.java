package com.alexmercerind.flutter_media_metadata;

import java.util.HashMap;
import java.lang.Runnable;
import java9.util.concurrent.CompletableFuture;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class FlutterMediaMetadataPlugin implements FlutterPlugin, MethodCallHandler {
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel =
        new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_media_metadata");
    channel.setMethodCallHandler(this);
  }

  @RequiresApi(api = Build.VERSION_CODES.N)
  @Override
  public void onMethodCall(@NonNull final MethodCall call, @NonNull final Result result) {
    if (call.method.equals("MetadataRetriever")) {
      final String filePath = (String) call.argument("filePath");
      CompletableFuture.runAsync(new Runnable() {
        @Override
        public void run() {
          MetadataRetriever retriever = new MetadataRetriever();
          retriever.setFilePath(filePath);
          final HashMap<String, Object> response = new HashMap<String, Object>();
          response.put("metadata", retriever.getMetadata());
          response.put("albumArt", retriever.getAlbumArt());
          retriever.release();
          new Handler(Looper.getMainLooper())
              .post(new Runnable() {
                @Override
                public void run() {
                  result.success(response);
                }
              });
        }
      });
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
