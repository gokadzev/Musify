import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;

import '../retry.dart';
import 'models/fragment.dart';
import 'models/stream_info_provider.dart';
import 'youtube_http_client.dart';

///
@internal
class DashManifest {
  static final _urlSignatureExp = RegExp(r'/s/(.*?)(?:/|$)');

  final xml.XmlDocument _root;

  ///
  late final Iterable<_StreamInfo> streams = parseMDP(_root);

  ///
  DashManifest(this._root);

  ///
  // ignore: deprecated_member_use
  DashManifest.parse(String raw) : _root = xml.XmlDocument.parse(raw);

  ///
  static Future<DashManifest> get(YoutubeHttpClient httpClient, dynamic url) {
    return retry(httpClient, () async {
      final raw = await httpClient.getString(url);
      return DashManifest.parse(raw);
    });
  }

  ///
  static String? getSignatureFromUrl(String url) =>
      _urlSignatureExp.firstMatch(url)?.group(1);

  bool _isDrmProtected(xml.XmlElement element) =>
      element.findElements('ContentProtection').isNotEmpty;

  _SegmentTimeline? extractSegmentTimeline(xml.XmlElement source) {
    final segmentTimeline = source.getElement('SegmentTimeline');
    if (segmentTimeline != null) {
      return _SegmentTimeline(
        segmentTimeline.findAllElements('S').map((e) {
          final d = int.tryParse(e.getAttribute('d') ?? '0')!;
          final r = int.tryParse(e.getAttribute('r') ?? '0')!;
          return _S(d, r);
        }).toList(),
      );
    }
    return null;
  }

  _MsInfo extractMultiSegmentInfo(
    xml.XmlElement element,
    _MsInfo msParentInfo,
  ) {
    final msInfo = msParentInfo.copy(); // Copy

    final segmentList = element.getElement('SegmentList');
    if (segmentList != null) {
      msInfo.segmentTimeline =
          extractSegmentTimeline(segmentList) ?? msParentInfo.segmentTimeline;
      msInfo.initializationUrl =
          segmentList.getElement('Initialization')?.getAttribute('sourceURL');

      final segmentUrlsSE = segmentList.findAllElements('SegmentURL');
      if (segmentUrlsSE.isNotEmpty) {
        msInfo.segmentUrls = [
          for (final segment in segmentUrlsSE) segment.getAttribute('media')!,
        ];
      }
    } else {
      final segmentTemplate = element.getElement('SegmentTemplate');
      if (segmentTemplate != null) {
        // Note: Currently SegmentTemplates are not supported.
/*        final segmentTimeLine = extractSegmentTimeline(segmentTemplate);
        if (segmentTimeLine != null) {
          msInfo['s'] = segmentTimeLine;
        }

        final timeScale = segmentTemplate.getAttribute('timescale');
        if (timeScale != null) {
          msInfo['timescale'] = int.parse(timeScale);
        }

        final media = segmentTemplate.getAttribute('media');
        if (media != null) {
          msInfo['media'] = media;
        }
        final initialization = segmentTemplate.getAttribute('initialization');
        if (initialization != null) {
          msInfo['initialization'] = initialization;
        } else {
          extractInitialization(segmentTemplate);
        }*/
      }
    }
    return msInfo;
  }

  List<_StreamInfo> parseMDP(xml.XmlDocument root) {
    if (root.getAttribute('type') == 'dynamic') {
      return const [];
    }

    final formats = <_StreamInfo>[];
    final periods = root.findAllElements('Period');
    for (final period in periods) {
      final periodMsInfo = extractMultiSegmentInfo(period, _MsInfo());
      final adaptionSets = period.findAllElements('AdaptationSet');
      for (final adaptionSet in adaptionSets) {
        if (_isDrmProtected(adaptionSet)) {
          continue;
        }
        final adaptionSetMsInfo =
            extractMultiSegmentInfo(adaptionSet, periodMsInfo);
        for (final representation
            in adaptionSet.findAllElements('Representation')) {
          if (_isDrmProtected(representation)) {
            continue;
          }
          final representationAttrib = {
            for (final e in adaptionSet.attributes) e.name.local: e.value,
            for (final e in representation.attributes) e.name.local: e.value,
          };

          final mimeType = MediaType.parse(representationAttrib['mimeType']!);

          if (mimeType.type == 'video' || mimeType.type == 'audio') {
            // Extract the base url
            final baseUrl = <xml.XmlElement>[
              ...representation.childElements,
              ...adaptionSet.childElements,
              ...period.childElements,
              ...root.childElements,
            ]
                .firstWhereOrNull((e) {
                  final baseUrlE = e.getElement('BaseURL')?.innerText.trim();
                  if (baseUrlE == null) {
                    return false;
                  }
                  return baseUrlE.contains(RegExp('^https?://'));
                })
                ?.innerText
                .trim();

            if (baseUrl == null || !baseUrl.startsWith('http')) {
              throw UnimplementedError(
                  'This kind of DASH Stream is not yet implemented. '
                  'Please open a new issue on this project GitHub.');
            }

            final representationMsInfo =
                extractMultiSegmentInfo(representation, adaptionSetMsInfo);

            if (representationMsInfo.segmentUrls != null &&
                representationMsInfo.segmentTimeline != null) {
              final fragments = <Fragment>[];
              var segmentIndex = 0;
              for (final s in representationMsInfo.segmentTimeline!.segments) {
                for (var i = 0; i < (s.r + 1); i++) {
                  final segmentUri =
                      representationMsInfo.segmentUrls![segmentIndex];
                  if (segmentUri.contains(RegExp('^https?://'))) {
                    throw UnimplementedError(
                        'This kind of DASH Stream is not yet implemented. '
                        'Please open a new issue on this project GitHub.');
                  }
                  fragments.add(Fragment(segmentUri));
                  segmentIndex++;
                }
              }
              representationMsInfo.fragments = fragments;
            }

            final fragments = <Fragment>[
              if (representationMsInfo.fragments != null &&
                  representationMsInfo.initializationUrl != null)
                Fragment(representationMsInfo.initializationUrl!),
              ...?representationMsInfo.fragments,
            ];

            formats.add(
              _StreamInfo(
                int.parse(representationAttrib['id']!),
                baseUrl,
                mimeType,
                int.tryParse(representationAttrib['width'] ?? ''),
                int.tryParse(representationAttrib['height'] ?? ''),
                int.tryParse(representationAttrib['frameRate'] ?? ''),
                fragments,
              ),
            );
          }
        }
      }
    }

    return formats;
  }
}

class _StreamInfo extends StreamInfoProvider {
  @override
  final int tag;

  @override
  final String url;

  @override
  final MediaType codec;

  @override
  String get container => codec.subtype;

  bool get isAudioOnly => codec.type == 'audio';

  @override
  String? get audioCodec => isAudioOnly ? codec.subtype : null;

  @override
  String? get videoCodec => isAudioOnly ? null : codec.subtype;

  @override
  @Deprecated('Use qualityLabel')
  String get videoQualityLabel => qualityLabel;

  @override
  late final String qualityLabel = 'DASH';

  @override
  final int? videoWidth;

  @override
  final int? videoHeight;

  @override
  final int? framerate;

  @override
  final List<Fragment> fragments;

  @override
  StreamSource get source => StreamSource.dash;

  _StreamInfo(
    this.tag,
    this.url,
    this.codec,
    this.videoWidth,
    this.videoHeight,
    this.framerate,
    this.fragments,
  );
}

class _SegmentTimeline {
  final List<_S> segments;

  const _SegmentTimeline(this.segments);
}

class _S {
  final int d;
  final int r;

  const _S(this.d, this.r);
}

class _MsInfo {
  int startNumber = 1;

  String? initializationUrl;
  _SegmentTimeline? segmentTimeline;
  List<String>? segmentUrls;
  List<Fragment>? fragments;

  _MsInfo();

  _MsInfo copy() {
    final v = _MsInfo();

    v.initializationUrl = initializationUrl;
    v.segmentTimeline = segmentTimeline;
    v.segmentUrls = segmentUrls;
    v.fragments = fragments;
    v.startNumber = startNumber;

    return v;
  }
}
