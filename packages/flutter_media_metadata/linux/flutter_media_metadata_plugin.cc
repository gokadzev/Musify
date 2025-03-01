#include "include/flutter_media_metadata/flutter_media_metadata_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <future>
#include <string>

#include "../cxx/metadata_retriever.hpp"

#define FLUTTER_MEDIA_METADATA_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_media_metadata_plugin_get_type(), \
                              FlutterMediaMetadataPlugin))

struct _FlutterMediaMetadataPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FlutterMediaMetadataPlugin, flutter_media_metadata_plugin,
              g_object_get_type())

MetadataRetriever* retriever = new MetadataRetriever();

static void flutter_media_metadata_plugin_handle_method_call(
    FlutterMediaMetadataPlugin* self, FlMethodCall* method_call) {
  if (strcmp(fl_method_call_get_name(method_call), "MetadataRetriever") == 0) {
    std::future<void> future = std::async([=]() -> void {
      auto arguments = fl_method_call_get_args(method_call);
      auto file_path =
          fl_value_get_string(fl_value_lookup_string(arguments, "filePath"));
      MetadataRetriever retriever;
      retriever.SetFilePath(file_path);
      auto metadata = fl_value_new_map();
      for (const auto& [key, value] : *retriever.metadata()) {
        fl_value_set_string(metadata, key.c_str(),
                            fl_value_new_string(value.c_str()));
      }
      auto response = fl_value_new_map();
      fl_value_set_string(response, "metadata", metadata);
      if (retriever.album_art() != nullptr) {
        fl_value_set_string(
            response, "albumArt",
            fl_value_new_uint8_list(retriever.album_art()->data(),
                                    retriever.album_art()->size()));
      } else {
        fl_value_set_string(response, "albumArt", fl_value_new_null());
      }
      fl_method_call_respond(
          method_call,
          FL_METHOD_RESPONSE(fl_method_success_response_new(response)),
          nullptr);
    });
  } else {
    fl_method_call_respond(
        method_call,
        FL_METHOD_RESPONSE(fl_method_not_implemented_response_new()), nullptr);
  }
}

static void flutter_media_metadata_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(flutter_media_metadata_plugin_parent_class)->dispose(object);
}

static void flutter_media_metadata_plugin_class_init(
    FlutterMediaMetadataPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = flutter_media_metadata_plugin_dispose;
}

static void flutter_media_metadata_plugin_init(
    FlutterMediaMetadataPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlutterMediaMetadataPlugin* plugin = FLUTTER_MEDIA_METADATA_PLUGIN(user_data);
  flutter_media_metadata_plugin_handle_method_call(plugin, method_call);
}

void flutter_media_metadata_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  FlutterMediaMetadataPlugin* plugin = FLUTTER_MEDIA_METADATA_PLUGIN(
      g_object_new(flutter_media_metadata_plugin_get_type(), nullptr));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "flutter_media_metadata", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);
  g_object_unref(plugin);
}
