class YoutubeApiClient {
  final Map<String, dynamic> payload;
  final String apiUrl;
  final Map<String, dynamic> headers;

  const YoutubeApiClient(this.payload, this.apiUrl, {this.headers = const {}});

  YoutubeApiClient.fromJson(Map<String, dynamic> json)
      : payload = json['payload'],
        apiUrl = json['apiUrl'],
        headers = json['headers'];

  Map<String, dynamic> toJson() => {
        'payload': payload,
        'apiUrl': apiUrl,
        'headers': headers,
      };

  // Client definitions are kept in sync with yt-dlp's INNERTUBE_CLIENTS:
  // https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/youtube/_base.py
  // Last cross-checked against yt-dlp master (commit b375e1d, 2026-08-18).

  /// Has limited streams but doesn't require signature deciphering.
  /// Now requires a PO Token for HTTPS/DASH GVS streams unless a player
  /// token is present (see [android]/[androidVr] for tokenless options).
  static final ios = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'IOS',
        'clientVersion': '21.26.4',
        'deviceMake': 'Apple',
        'deviceModel': 'iPhone16,2',
        'userAgent':
            'com.google.ios.youtube/21.26.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)',
        'hl': 'en',
        "platform": "MOBILE",
        'osName': 'IOS',
        'osVersion': '18.3.2.22D82',
        'timeZone': 'UTC',
        'gl': 'US',
        'utcOffsetMinutes': 0
      }
    },
  }, 'https://www.youtube.com/youtubei/v1/player?key=AIzaSyB-63vPrdThhKuerbB2N_l7Kwwcxj6yUAc&prettyPrint=false');

  /// This provides also muxed streams but seems less reliable than [ios].
  /// If you require an android client use [androidVr] instead.
  /// Note: This client includes androidSdkVersion, which yt-dlp now marks as
  /// requiring a PO Token for GVS HTTPS/DASH streams (unless a player token
  /// is present). [androidVr] is currently the more reliable tokenless pick.
  static const android = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'ANDROID',
        'clientVersion': '21.26.364',
        'androidSdkVersion': 30,
        'userAgent':
            'com.google.android.youtube/21.26.364 (Linux; U; Android 11) gzip',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
        'osName': 'Android',
        'osVersion': '11',
      },
    },
  }, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

  /// yt-dlp removed its `android_sdkless` client in Jan 2026 (yt-dlp#15726):
  /// YouTube's CDN started blocking it outright. It is kept here only for
  /// source compatibility and now simply forwards to [android].
  /// Prefer [androidVr] (or [android]) instead.
  @Deprecated(
      'YouTube blocks the android_sdkless variant as of 2026. Use androidVr or android instead.')
  static const androidSdkless = android;

  /// yt-dlp dropped the dedicated `android_music` (ANDROID_MUSIC) client;
  /// music.youtube.com metadata/streams are now served through the WEB_REMIX
  /// client instead. This entry is kept only for backwards compatibility and
  /// is not guaranteed to keep working.
  @Deprecated(
      'yt-dlp removed the ANDROID_MUSIC client; YouTube Music now uses WEB_REMIX. This may stop working at any time.')
  static const androidMusic = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'ANDROID_MUSIC',
        'clientVersion': '2.16.032',
        'androidSdkVersion': 31,
        'userAgent':
            'com.google.android.youtube/19.29.1  (Linux; U; Android 11) gzip',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
    },
  }, 'https://music.youtube.com/youtubei/v1/player?key=AIzaSyAOghZGza2MQSZkY_zfZ370N-PUdXEo8AI&prettyPrint=false');

  /// Provides high quality videos (not only VR) and, as of yt-dlp master,
  /// does not require a PO Token for most requests. It is currently the
  /// **default fallback client** used by yt-dlp itself (together with
  /// [visionOs] and [safari]/web).
  ///
  /// Note (from yt-dlp): "Made for kids" videos aren't available with this
  /// client. Using a clientVersion above 1.65 may return SABR-only streams,
  /// and since 2026-07 YouTube has been observed to intermittently/
  /// selectively enforce PO Tokens on this client for non-HLS formats. If
  /// this client starts failing, fall back to [visionOs] or [safari].
  static const androidVr = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'ANDROID_VR',
        'clientVersion': '1.65.10',
        'deviceMake': 'Oculus',
        'deviceModel': 'Quest 3',
        'osVersion': '12L',
        'osName': 'Android',
        'androidSdkVersion': 32,
        'userAgent':
            'com.google.android.apps.youtube.vr.oculus/1.65.10 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
    },
  }, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

  /// Apple Vision Pro client. As of yt-dlp master this is the **first**
  /// entry in yt-dlp's default client list (ahead of [androidVr]), likely
  /// because it currently doesn't require a PO Token at all and hasn't seen
  /// the intermittent enforcement [androidVr] has. "Made for kids" videos
  /// aren't available with this client either.
  static const visionOs = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'VISIONOS',
        'clientVersion': '1.02',
        'deviceMake': 'Apple',
        'deviceModel': 'RealityDevice17,1',
        'userAgent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
        'osName': 'visionOS',
        'osVersion': '26.5.23O471',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
    },
  }, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

  /// This client also provide high quality muxed stream in the HLS manifest.
  /// The streams are in m3u8 format.
  /// Note: since 2026-07 YouTube only returns these merged HLS formats for
  /// some logged-in or "trusted" sessions; anonymous requests may get fewer
  /// formats than before.
  static const safari = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'WEB',
        'clientVersion': '2.20260708.00.00',
        'userAgent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15,gzip(gfe)',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
    },
  }, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

  /// Used to bypass same restriction on videos.
  static const tv = YoutubeApiClient(
      {
        'context': {
          'client': {
            "deviceMake": "",
            "deviceModel": "",
            "userAgent":
                "Mozilla/5.0 (ChromiumStylePlatform) Cobalt/25.lts.30.1034943-gold (unlike Gecko), Unknown_TV_Unknown_0/Unknown (Unknown, Unknown)",
            'clientName': 'TVHTML5',
            "clientVersion": "7.20260707.07.00",
            'hl': 'en',
            'timeZone': 'UTC',
            'gl': 'US',
            'utcOffsetMinutes': 0,
            "originalUrl": "https://www.youtube.com/tv",
            "theme": "CLASSIC",
            "platform": "DESKTOP",
            "clientFormFactor": "UNKNOWN_FORM_FACTOR",
            "webpSupport": false,
            "configInfo": {},
            "tvAppInfo": {"appQuality": "TV_APP_QUALITY_FULL_ANIMATION"},
            "acceptHeader":
                "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
          },
          "user": {"lockedSafetyMode": false},
          "request": {"useSsl": true},
        },
        "contentCheckOk": true,
        "racyCheckOk": true,
      },
      'https://www.youtube.com/youtubei/v1/player?prettyPrint=false',
      headers: {
        'Sec-Fetch-Mode': 'navigate',
        'Content-Type': 'application/json',
        'Origin': 'https://www.youtube.com',
      });

  /// yt-dlp's client used for logged-in ("free account") extraction, paired
  /// with [safari]/web. Uses an older TVHTML5 build than [tv].
  static const tvDowngraded = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'TVHTML5',
        'clientVersion': '5.20260707',
        'userAgent': 'Mozilla/5.0 (ChromiumStylePlatform) Cobalt/Version',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
    },
  }, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

  static const mediaConnect = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'MEDIA_CONNECT_FRONTEND',
        'clientVersion': '0.1',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
    },
  }, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

  /// Sometimes includes low quality streams (eg. 144p12).
  /// Now requires a PO Token for HTTPS/DASH GVS streams.
  static const mweb = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'MWEB',
        'clientVersion': '2.20260708.05.00',
        'userAgent':
            'Mozilla/5.0 (iPad; CPU OS 16_7_10 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1,gzip(gfe)',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
    },
  }, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

  @Deprecated('Youtube always requires authentication for this client')
  static const webCreator = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'WEB_CREATOR',
        'clientVersion': '1.20260708.06.00',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
    },
  }, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

  /// Work even of restricted videos and provides low quality muxed streams, but requires signature deciphering.
  /// Does not work if the video has the embedding disabled.
  @Deprecated('Youtube always requires authentication for this client')
  static const tvSimplyEmbedded = YoutubeApiClient(
      {
        'context': {
          'client': {
            'clientName': 'TVHTML5_SIMPLY_EMBEDDED_PLAYER',
            'clientVersion': '2.0',
            'hl': 'en',
            'timeZone': 'UTC',
            'gl': 'US',
            'utcOffsetMinutes': 0
          }
        },
        'thirdParty': {'embedUrl': 'https://www.youtube.com/'},
        'contentCheckOk': true,
        'racyCheckOk': true
      },
      'https://www.youtube.com/youtubei/v1/player?prettyPrint=false',
      headers: {
        'Sec-Fetch-Mode': 'navigate',
        'Content-Type': 'application/json',
        'Origin': 'https://www.youtube.com',
      });
}
