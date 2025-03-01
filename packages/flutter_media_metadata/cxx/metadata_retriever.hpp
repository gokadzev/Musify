/// This file is a part of flutter_media_metadata
/// (https://github.com/alexmercerind/flutter_media_metadata).
///
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the
/// LICENSE file.

#ifndef UNICODE
#define UNICODE
#endif
#include <MediaInfoDLL/MediaInfoDLL.hpp>
#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <vector>

#ifndef METADATA_RETRIEVER_HEADER
#define METADATA_RETRIEVER_HEADER

class MetadataRetriever : public MediaInfoDLL::MediaInfo {
 public:
  MetadataRetriever();

  std::map<std::string, std::string>* metadata() const {
    return metadata_.get();
  }
  std::vector<uint8_t>* album_art() const { return album_art_.get(); }

  void SetFilePath(std::string file_path);

  ~MetadataRetriever();

 private:
  std::unique_ptr<std::map<std::string, std::string>> metadata_ =
      std::make_unique<std::map<std::string, std::string>>();
  std::unique_ptr<std::vector<uint8_t>> album_art_ = nullptr;
};

#endif
