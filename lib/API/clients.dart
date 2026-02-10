/// Credit: Based on yt-dlp YouTube extractor implementation
/// https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/youtube/_base.py

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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

const customAndroidSdkless = YoutubeApiClient({
  'context': {
    'client': {
      'clientName': 'ANDROID',
      'clientVersion': '20.10.38',
      'userAgent':
          'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip',
      'osName': 'Android',
      'osVersion': '11',
    },
  },
  'contextClientName': 3,
  'requireJsPlayer': false,
}, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');
