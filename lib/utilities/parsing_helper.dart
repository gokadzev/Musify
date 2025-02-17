import 'dart:convert';
import 'dart:math';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

var _visitorData = YoutubeParsingHelper.getRandomVisitorData();

class YoutubeParsingHelper {
  static const String _contentPlaybackNonceAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  static String getRandomVisitorData() {
    final random = Random();
    final pbE2 = ProtoBuilder()
      ..string(2, '')
      ..varint(4, random.nextInt(255) + 1);

    final pbE = ProtoBuilder()
      ..string(1, 'US')
      ..bytes(2, pbE2.toBytes());

    final pb = ProtoBuilder()
      ..string(
        1,
        _generateRandomStringFromAlphabet(
          _contentPlaybackNonceAlphabet,
          11,
          random,
        ),
      )
      ..varint(
        5,
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - random.nextInt(600000),
      )
      ..bytes(6, pbE.toBytes());
    return pb.toUrlencodedBase64();
  }

  static String _generateRandomStringFromAlphabet(
    String alphabet,
    int length,
    Random random,
  ) {
    final sb = StringBuffer();
    for (var i = 0; i < length; i++) {
      sb.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return sb.toString();
  }
}

class ProtoBuilder {
  final Map<int, dynamic> _fields = {};

  void string(int fieldNumber, String value) {
    _fields[fieldNumber] = value;
  }

  void varint(int fieldNumber, int value) {
    _fields[fieldNumber] = value;
  }

  void bytes(int fieldNumber, List<int> value) {
    _fields[fieldNumber] = value;
  }

  List<int> toBytes() {
    final bytes = <int>[];
    _fields.forEach((key, value) {
      if (value is String) {
        bytes.addAll(utf8.encode(value));
      } else if (value is int) {
        bytes.add(value);
      } else if (value is List<int>) {
        bytes.addAll(value);
      }
    });
    return bytes;
  }

  String toUrlencodedBase64() {
    final bytes = toBytes();
    return base64Url.encode(bytes);
  }
}

var iosNew = YoutubeApiClient(
  {
    'context': {
      'client': {
        'clientName': 'IOS',
        'clientVersion': '19.45.4',
        'deviceMake': 'Apple',
        'deviceModel': 'iPhone16,2',
        'hl': 'en',
        'platform': 'MOBILE',
        'osName': 'IOS',
        'osVersion': '18.1.0.22B83',
        'visitorData': _visitorData,
      },
      'gl': 'US',
      'utcOffsetMinutes': 0,
    },
  },
  'https://www.youtube.com/youtubei/v1/player?key=AIzaSyB-63vPrdThhKuerbB2N_l7Kwwcxj6yUAc&prettyPrint=false',
);
