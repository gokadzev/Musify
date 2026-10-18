#include "media_controls.h"

#include <flutter/standard_method_codec.h>
#include <systemmediatransportcontrolsinterop.h>
#include <shcore.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Storage.Streams.h>

#include <iostream>
#include <variant>

namespace {
constexpr UINT kMediaButtonMessage = WM_APP + 13;
using namespace winrt::Windows::Media;
using namespace winrt::Windows::Storage::Streams;

std::string ReadString(const flutter::EncodableMap& args, const char* key) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it != args.end()) {
    if (const auto* value = std::get_if<std::string>(&it->second)) {
      return *value;
    }
  }
  return {};
}

bool ReadBool(const flutter::EncodableMap& args, const char* key) {
  auto it = args.find(flutter::EncodableValue(key));
  return it != args.end() && std::holds_alternative<bool>(it->second) &&
         std::get<bool>(it->second);
}
}  // namespace

MediaControls::MediaControls(HWND window, flutter::BinaryMessenger* messenger)
    : window_(window) {
  channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "musify/media_controls",
          &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleCall(call, std::move(result));
      });
}

MediaControls::~MediaControls() {
  channel_->SetMethodCallHandler(nullptr);
  Dispose();
}

void MediaControls::Initialize() {
  if (controls_) return;
  const auto interop = winrt::get_activation_factory<
      SystemMediaTransportControls, ISystemMediaTransportControlsInterop>();
  winrt::check_hresult(interop->GetForWindow(
      window_, winrt::guid_of<SystemMediaTransportControls>(),
      winrt::put_abi(controls_)));
  controls_.IsEnabled(false);
  controls_.IsPlayEnabled(true);
  controls_.IsPauseEnabled(true);
  controls_.IsStopEnabled(true);
  controls_.IsNextEnabled(false);
  controls_.IsPreviousEnabled(false);
  controls_.PlaybackStatus(MediaPlaybackStatus::Stopped);

  // SMTC raises this on a worker thread. Only post a value to the window;
  // invoking a Flutter channel here would violate its platform thread rule.
  button_token_ = controls_.ButtonPressed(
      [window = window_](const auto&, const auto& args) {
        PostMessage(window, kMediaButtonMessage,
                    static_cast<WPARAM>(args.Button()), 0);
      });
  subscribed_ = true;
}

void MediaControls::Dispose() {
  enabled_ = false;
  has_metadata_ = false;
  if (!controls_) return;
  try {
    if (subscribed_) {
      controls_.ButtonPressed(button_token_);
      subscribed_ = false;
    }
    controls_.IsEnabled(false);
    controls_.PlaybackStatus(MediaPlaybackStatus::Closed);
    auto updater = controls_.DisplayUpdater();
    updater.ClearAll();
    updater.Update();
  } catch (const winrt::hresult_error& error) {
    std::cerr << "SMTC cleanup: " << winrt::to_string(error.message()) << '\n';
  }
  controls_ = nullptr;
}

void MediaControls::Update(const flutter::EncodableMap& args) {
  if (!controls_) return;
  enabled_ = ReadBool(args, "enabled");
  can_go_next_ = enabled_ && ReadBool(args, "canGoNext");
  can_go_previous_ = enabled_ && ReadBool(args, "canGoPrevious");
  controls_.IsNextEnabled(can_go_next_);
  controls_.IsPreviousEnabled(can_go_previous_);
  if (!enabled_) {
    controls_.PlaybackStatus(MediaPlaybackStatus::Stopped);
    controls_.IsEnabled(false);
    if (has_metadata_) {
      auto updater = controls_.DisplayUpdater();
      updater.ClearAll();
      updater.Update();
      has_metadata_ = false;
    }
    return;
  }

  const auto title = ReadString(args, "title");
  const auto artist = ReadString(args, "artist");
  const auto album = ReadString(args, "album");
  const auto art_uri = ReadString(args, "artUri");
  const auto art_path = ReadString(args, "artPath");
  if (!has_metadata_ || title != title_ || artist != artist_ ||
      album != album_ || art_uri != art_uri_ || art_path != art_path_) {
    auto updater = controls_.DisplayUpdater();
    updater.ClearAll();
    updater.Type(MediaPlaybackType::Music);
    updater.MusicProperties().Title(winrt::to_hstring(title));
    updater.MusicProperties().Artist(winrt::to_hstring(artist));
    updater.MusicProperties().AlbumTitle(winrt::to_hstring(album));
    // Artwork errors must not prevent transport controls or text updates.
    try {
      if (!art_path.empty()) {
        IRandomAccessStream stream{nullptr};
        winrt::check_hresult(CreateRandomAccessStreamOnFile(
            winrt::to_hstring(art_path).c_str(), 0 /* FileAccessMode::Read */,
            winrt::guid_of<IRandomAccessStream>(), winrt::put_abi(stream)));
        updater.Thumbnail(RandomAccessStreamReference::CreateFromStream(stream));
      } else if (!art_uri.empty()) {
        updater.Thumbnail(RandomAccessStreamReference::CreateFromUri(
            winrt::Windows::Foundation::Uri(winrt::to_hstring(art_uri))));
      }
    } catch (const winrt::hresult_error& error) {
      std::cerr << "SMTC artwork: " << winrt::to_string(error.message()) << '\n';
    }
    updater.Update();
    title_ = title;
    artist_ = artist;
    album_ = album;
    art_uri_ = art_uri;
    art_path_ = art_path;
    has_metadata_ = true;
  }
  controls_.PlaybackStatus(ReadString(args, "status") == "playing"
                               ? MediaPlaybackStatus::Playing
                               : MediaPlaybackStatus::Paused);
  controls_.IsEnabled(true);
}

bool MediaControls::HandleMessage(UINT message, WPARAM button) {
  if (message != kMediaButtonMessage) return false;
  if (!enabled_) return true;
  const char* command = nullptr;
  switch (static_cast<SystemMediaTransportControlsButton>(button)) {
    case SystemMediaTransportControlsButton::Play: command = "play"; break;
    case SystemMediaTransportControlsButton::Pause: command = "pause"; break;
    case SystemMediaTransportControlsButton::Next:
      if (!can_go_next_) return true;
      command = "next"; break;
    case SystemMediaTransportControlsButton::Previous:
      if (!can_go_previous_) return true;
      command = "previous"; break;
    case SystemMediaTransportControlsButton::Stop: command = "stop"; break;
    default: return true;
  }
  channel_->InvokeMethod("button",
                        std::make_unique<flutter::EncodableValue>(command));
  return true;
}

void MediaControls::HandleCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  try {
    if (call.method_name() == "initialize") {
      Initialize();
    } else if (call.method_name() == "update") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (!args) {
        result->Error("bad_args", "Expected media state map");
        return;
      }
      Update(*args);
    } else if (call.method_name() == "dispose") {
      Dispose();
    } else {
      result->NotImplemented();
      return;
    }
    result->Success();
  } catch (const winrt::hresult_error& error) {
    result->Error("smtc_error", winrt::to_string(error.message()));
  }
}
