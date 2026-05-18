import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final customClients = [customAndroidVr];

const customAndroidVr = YoutubeApiClient({
  'context': {
    'client': {
      'clientName': 'ANDROID_VR',
      'clientVersion': '1.65.10',
      'deviceModel': 'Quest 3',
      'osVersion': '12L',
      'osName': 'Android',
      'androidSdkVersion': '32',
      'hl': 'en',
      'timeZone': 'UTC',
      'utcOffsetMinutes': 0,
    },
    'contextClientName': 28,
    'requireJsPlayer': false,
  },
}, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');
