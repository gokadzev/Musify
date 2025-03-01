/// This file is a part of flutter_media_metadata
/// (https://github.com/alexmercerind/flutter_media_metadata).
///
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the
/// LICENSE file.

#include "metadata_retriever.hpp"

#include <base64.hpp>

#include "utils.hpp"

static const std::map<std::string, std::wstring> kMetadataKeys = {
    {"trackName", L"Track"},
    {"trackArtistNames", L"Performer"},
    {"albumName", L"Album"},
    {"albumArtistName", L"Album/Performer"},
    {"trackNumber", L"Track/Position"},
    {"albumLength", L"Track/Position_Total"},
    {"year", L"Recorded_Date"},
    {"genre", L"Genre"},
    {"writerName", L"WrittenBy"},
    {"trackDuration", L"Duration"},
    {"bitrate", L"OverallBitRate"},
};

MetadataRetriever::MetadataRetriever() { Option(L"Cover_Data", L"base64"); }

void MetadataRetriever::SetFilePath(std::string file_path) {
  Open(TO_WIDESTRING(file_path));
  for (auto& [property, key] : kMetadataKeys) {
    std::string value = TO_STRING(Get(MediaInfoDLL::Stream_General, 0, key));
    metadata_->insert(std::make_pair(property, value));
  }
  metadata_->insert(std::make_pair("filePath", file_path));
  try {
    if (Get(MediaInfoDLL::Stream_General, 0, L"Cover") == L"Yes") {
      std::vector<uint8_t> decoded_album_art = Base64Decode(
          TO_STRING(Get(MediaInfoDLL::Stream_General, 0, L"Cover_Data")));
      album_art_.reset(new std::vector<uint8_t>(decoded_album_art));
      // Apparently libmediainfo already handles the seeking of album art
      // buffer in FLAC.
      // Its a bug in libmediainfo itself that it doesn't seek
      // METADATA_BLOCK_PICTURE in OGG & assigns it to "Cover_Data" itself.
      //
      // Letting following header seeking code stay for OGG until they fix it.
      // Further reference:
      // https://github.com/harmonoid/harmonoid/issues/76
      // https://github.com/MediaArea/MediaInfoLib/pull/1098
      //
      auto format = TO_STRING(Get(MediaInfoDLL::Stream_General, 0, L"Format"));
      if (Strings::ToUpperCase(format) == "OGG") {
        uint8_t* data = decoded_album_art.data();
        size_t size = decoded_album_art.size();
        size_t header = 0;
        uint32_t length = 0;
        RM(4);
        length = U32_AT(data);
        header += length;
        RM(4);
        RM(length);
        length = U32_AT(data);
        header += length;
        RM(4);
        RM(length);
        RM(4 * 4);
        length = U32_AT(data);
        RM(4);
        header += 32;
        size = length;
        album_art_.reset(new std::vector(data, data + length));
      }
    } else {
      album_art_ = nullptr;
    }
  } catch (...) {
    album_art_ = nullptr;
  }
}

MetadataRetriever::~MetadataRetriever() {}
