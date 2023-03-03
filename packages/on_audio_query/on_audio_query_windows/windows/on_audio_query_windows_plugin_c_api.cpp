#include "include/on_audio_query_windows/on_audio_query_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "on_audio_query_windows_plugin.h"

void OnAudioQueryWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  on_audio_query_windows::OnAudioQueryWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
