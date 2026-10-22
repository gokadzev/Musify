#ifndef RUNNER_MEDIA_CONTROLS_H_
#define RUNNER_MEDIA_CONTROLS_H_

#include <windows.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <winrt/Windows.Media.h>

#include <memory>
#include <string>

// Owns one SMTC session tied to the app's top-level HWND. No second audio player
// is created: all transport commands go back to Musify's existing Dart handler.
class MediaControls {
 public:
  MediaControls(HWND window, flutter::BinaryMessenger* messenger);
  ~MediaControls();

  bool HandleMessage(UINT message, WPARAM button);

 private:
  void Initialize();
  void Dispose();
  void Update(const flutter::EncodableMap& args);
  void HandleCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  winrt::Windows::Media::SystemMediaTransportControls controls_{nullptr};
  winrt::event_token button_token_{};
  bool subscribed_ = false;
  bool enabled_ = false;
  bool can_go_next_ = false;
  bool can_go_previous_ = false;
  bool has_metadata_ = false;
  std::string title_, artist_, album_, art_uri_, art_path_;
};

#endif  // RUNNER_MEDIA_CONTROLS_H_
