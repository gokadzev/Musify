import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  YoutubeExplode? yt;
  setUpAll(() {
    yt = YoutubeExplode();
  });

  tearDownAll(() {
    yt?.close();
  });

  test('Get a channel about page', () async {
    const channelUrl = 'https://www.youtube.com/user/FavijTV';
    final channel = await yt!.channels.getAboutPageByUsername(channelUrl);
    expect(channel.country, 'Italy');
    expect(channel.thumbnails, isNotEmpty);
    expect(channel.channelLinks, isNotEmpty);
    expect(channel.description, isNotEmpty);
    expect(channel.joinDate, isNotEmpty);
    expect(channel.title, 'FavijTV');
    expect(channel.viewCount, greaterThanOrEqualTo(3631224938));
  }, skip: 'Currently broken');
}
