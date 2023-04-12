import 'package:audio_service_platform_interface/audio_service_platform_interface.dart';

const asciiSquare = '▮';

abstract class Stubs {
  static const parentMediaId = 'id';
  static const mediaId = 'id';
  static const mediaItem = MediaItemMessage(
    id: mediaId,
    title: 'title',
  );
  static const queue = [mediaItem];
  static const searchQuery = 'search query';
  static final uri = Uri.file('file');
  static const map = <String, dynamic>{'key': 'value'};
  static const index = 0;
}
