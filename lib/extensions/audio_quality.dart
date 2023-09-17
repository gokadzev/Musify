import 'package:musify/enums/quality_enum.dart';

extension AudioQualityExtension on AudioQuality {
  String get stringValue {
    switch (this) {
      case AudioQuality.lowQuality:
        return 'lowQuality';
      case AudioQuality.mediumQuality:
        return 'mediumQuality';
      case AudioQuality.bestQuality:
        return 'bestQuality';
      default:
        throw Exception('Unsupported AudioQuality');
    }
  }

  static AudioQuality fromString(String value) {
    switch (value) {
      case 'lowQuality':
        return AudioQuality.lowQuality;
      case 'mediumQuality':
        return AudioQuality.mediumQuality;
      case 'bestQuality':
        return AudioQuality.bestQuality;
      default:
        throw Exception('Unsupported AudioQuality string');
    }
  }
}
