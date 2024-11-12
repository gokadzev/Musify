# audiotagger
![build status](https://img.shields.io/badge/build-passing-brightgreen?style=flat-square)
[![pub](https://img.shields.io/pub/v/audiotagger?style=flat-square)](https://pub.dev/packages/audiotagger)

This library allow you to read and write ID3 tags to MP3 files.  \
Based on **JAudiotagger** library.

> **Library actually works only on Android.**

## Add dependency
```yaml
dependencies:
  audiotagger: ^2.2.1
```
Audiotagger need access to read and write storage.  \
To do this you can use [Permission Handler library](https://pub.dev/packages/permission_handler).

## Table of contents
- [Basic usage](#basic-usage)
- [Reading operations](#reading-operations)
    - [Read tags as `Tag` object](#read-tags-as-tag-object)
    - [Read tags as map](#read-tags-as-map)
    - [Read artwork](#read-artwork)
    - [Read audio file as `AudioFile` object](#read-audio-file-as-audiofile-object)
    - [Read audio file as map](#read-audio-file-as-map)
- [Writing operations](#writing-operations)
    - [Write tags from map](#write-tags-from-map)
    - [Write tags from `Tag` object](#write-tags-from-tag-object)
    - [Write single tag field](#write-single-tag-field)
- [Models](#models)
    - [`Tag` class](#tag-class)
        - [`Map` of `Tag`](#map-of-tag)
    - [`AudioFile` class](#audiofile-class)
        - [`Map` of `AudioFile`](#map-of-audiofile)


## Basic usage
Initialize a new instance of the tagger;
```dart
final tagger = new Audiotagger();
```

## Reading operations

### Read tags as `Tag` object
Obtain ID3 tags of the file as a `Tag` object.
```dart
void getTags() async {
    final String filePath = "/storage/emulated/0/file.mp3";
    final Tag tag = await tagger.readTags(
        path: filePath
    );
}
```

[**This method does not read the artwork of the song. To do this, use the `readArtwork` method.**](#read-artwork)

The `Tag` object has this schema: [`Tag` schema](#tag-class).

### Read tags as map
Obtain ID3 tags of the file as a `Map`.
```dart
void getTagsAsMap() async {
    final String filePath = "/storage/emulated/0/file.mp3";
    final Map map = await tagger.readTagsAsMap(
        path: filePath
    );
}
```
[**This method does not read the artwork of the song. To do this, use the `readArtwork` method.**](#read-artwork)

The map has this schema: [`Map` of `Tag` schema](#map-of-tag).

### Read artwork
Obtain the artwork of the song as a `Uint8List`.
```dart
void getArtwork() async {
    final String filePath = "/storage/emulated/0/file.mp3";
    final Uint8List bytes = await tagger.readArtwork(
        path: filePath
    );
}
```

### Read audio file as `AudioFile` object
Obtain informations about the MP3 file as a `Tag` object.
```dart
void getAudioFile() async {
    final String filePath = "/storage/emulated/0/file.mp3";
    final AudioFile audioFile = await tagger.readAudioFile(
        path: filePath
    );
}
```

The `AudioFile` object has this schema: [`AudioFile` schema](#audiofile-class).

### Read audio file as map
Obtain informations about the MP3 file as a `Map`.
```dart
void getAudioFileAsMap() async {
    final String filePath = "/storage/emulated/0/file.mp3";
    final Map map = await tagger.readAudioFileAsMap(
        path: filePath
    );
}
```

The map has this schema: [`Map` of `AudioFile` schema](#map-of-audiofile).

## Writing operations

### Write tags from map
You can write the ID3 tags from a `Map`.  \
To reset a field, pass an empty string (`""`).  \
If the value is `null`, the field will be ignored and it will not be written.

```dart
void setTagsFromMap() async {
    final path = "storage/emulated/0/Music/test.mp3";
    final tags = <String, String>{
        "title": "Title of the song",
        "artist": "A fake artist",
        "album": "",    //This field will be reset
        "genre": null,  //This field will not be written
    };

    final result = await tagger.writeTagsFromMap(
        path: path,
        tags: tags
    );
}
```

The map has this schema: [`Map` of `Tag` schema](#map-of-tag).

### Write tags from `Tag` object
You can write the ID3 tags from a `Tag` object.  \
To reset a field, pass an empty string (`""`).  \
If the value is `null`, the field will be ignored and it will not be written.

```dart
void setTags() async {
    final path = "storage/emulated/0/Music/test.mp3";
    final tag = Tag(
        title: "Title of the song",
        artist: "A fake artist",
        album: "",    //This field will be reset
        genre: null,  //This field will not be written
    );

    final result = await tagger.writeTags(
        path: path,
        tag: tag,
    );
}
```

The `Tag` object has this schema: [`Tag` schema](#tag-class).

### Write single tag field
You can write a single tag field by specifying the field name.  \
To reset the field, pass an empty string (`""`).  \
If the value is `null`, the field will be ignored and it will not be written.  \

```dart
void setTags() async {
    final path = "storage/emulated/0/Music/test.mp3";

    final result = await tagger.writeTag(
        path: path,
        tagField: "title",
        value: "Title of the song"
    );
}
```

Refer to [`Map` of `Tag` schema](#map-of-tag) for fields name.

## Models

These are the schemes of the `Map` and classes asked and returned by Audiotagger.

### `Tag` class
```dart
String? title;
String? artist;
String? genre;
String? trackNumber;
String? trackTotal;
String? discNumber;
String? discTotal;
String? lyrics;
String? comment;
String? album;
String? albumArtist;
String? year;
String? artwork; // It represents the file path of the song artwork.
```

### `Map` of `Tag`
```dart
<String, String>{
    "title": value,
    "artist": value,
    "genre": value,
    "trackNumber": value,
    "trackTotal": value,
    "discNumber": value,
    "discTotal": value,
    "lyrics": value,
    "comment": value,
    "album": value,
    "albumArtist": value,
    "year": value,
    "artwork": value, // Null if obtained from readTags or readTagsAsMap
};
```

### `AudioFile` class
```dart
int? length;
int? bitRate;
String? channels;
String? encodingType;
String? format;
int? sampleRate;
bool? isVariableBitRate;
```

### `Map` of `AudioFile`
```dart
<String, dynamic?>{
    "length": length,
    "bitRate": bitRate,
    "channels": channels,
    "encodingType": encodingType,
    "format": format,
    "sampleRate": sampleRate,
    "isVariableBitRate": isVariableBitRate,
};
```

## Copyright and license
This library is developed and maintained by Nicolò Rebaioli  
:globe_with_meridians: [My website](https://rebaioli.altervista.org)  
:mailbox: [niko.reba@gmail.com](mailto:niko.reba@gmail.com)

Released under [MIT license](LICENSE)

Copyright 2021 Nicolò Rebaioli