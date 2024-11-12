import 'dart:typed_data';

import 'package:audiotagger/models/audiofile.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audiotagger/audiotagger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('audiotagger');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      final args = Map<String, dynamic>.from(methodCall.arguments);
      switch (methodCall.method) {
        case 'writeTags':
          if (args.containsKey("path") &&
              args.containsKey("tags") &&
              args.containsKey("artwork")) {
            return true;
          } else {
            throw new Exception('Missing parameter');
          }
        case 'readTags':
          if (args.containsKey("path"))
            return <String, String>{
              "title": "Title of the song",
              "artist": "A fake artist",
              "album": "A fake album",
              "year": "2020",
            };
          else
            throw new Exception('Missing parameter');
        case 'readArtwork':
          if (args.containsKey("path"))
            return Uint8List(2048);
          else
            throw new Exception('Missing parameter');
        default:
          throw new Exception('Method not implemented');
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  group("writing", () {
    test('writeTagsFromMap', () async {
      final tagger = new Audiotagger();

      final path = "storage/emulated/0/Music/test.mp3";
      final tags = <String, String>{
        "title": "Title of the song",
        "artist": "A fake artist",
        "album": "A fake album",
        "year": "2020",
      };

      final result = await tagger.writeTagsFromMap(
        path: path,
        tags: tags,
      );

      expect(result, true);
    });

    test('writeTags', () async {
      final tagger = new Audiotagger();

      final path = "storage/emulated/0/Music/test.mp3";
      final tags = <String, String>{
        "title": "Title of the song",
        "artist": "A fake artist",
        "album": "A fake album",
        "year": "2020",
      };
      final tag = Tag.fromMap(tags);

      final result = await tagger.writeTags(
        path: path,
        tag: tag,
      );

      expect(result, true);
    });
  });

  group("reading", () {
    test('readTagsAsMap', () async {
      final tagger = new Audiotagger();

      final path = "storage/emulated/0/Music/test.mp3";
      final tagMap = <String, String>{
        "title": "Title of the song",
        "artist": "A fake artist",
        "album": "A fake album",
        "year": "2020",
      };

      final result = await tagger.readTagsAsMap(
        path: path,
      );

      expect(result!, tagMap);
    });

    test('readTags', () async {
      final tagger = new Audiotagger();

      final path = "storage/emulated/0/Music/test.mp3";
      final tagMap = <String, String>{
        "title": "Title of the song",
        "artist": "A fake artist",
        "album": "A fake album",
        "year": "2020",
      };
      final tag = Tag.fromMap(tagMap);

      final result = await tagger.readTags(
        path: path,
      );

      expect(result!.toMap(), tag.toMap());
    });

    test('readArtwork', () async {
      final tagger = new Audiotagger();

      final path = "storage/emulated/0/Music/test.mp3";

      final artwork = Uint8List(2048); // Mocked artwork

      final result = await tagger.readArtwork(
        path: path,
      );

      expect(result!, artwork);
    });

    test('readAudioFileAsMap', () async {
      final tagger = new Audiotagger();

      final path = "storage/emulated/0/Music/test.mp3";
      final audiofileMap = <String, dynamic>{
        "channels": "Stereo",
        "isVariableBitRate": false,
        "bitRate": 256,
        "encodingType": "mp3",
        "length": 132,
        "format": "MPEG-1 Layer 3",
        "sampleRate": 44100
      };

      final result = await tagger.readAudioFileAsMap(
        path: path,
      );

      expect(result!, audiofileMap);
    });

    test('readAudioFile', () async {
      final tagger = new Audiotagger();

      final path = "storage/emulated/0/Music/test.mp3";
      final audiofileMap = <String, dynamic>{
        "channels": "Stereo",
        "isVariableBitRate": false,
        "bitRate": 256,
        "encodingType": "mp3",
        "length": 132,
        "format": "MPEG-1 Layer 3",
        "sampleRate": 44100
      };
      final audiofile = AudioFile.fromMap(audiofileMap);

      final result = await tagger.readAudioFile(
        path: path,
      );

      expect(result!.toMap(), audiofile.toMap());
    });
  });
}
