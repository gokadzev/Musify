import '../../reverse_engineering/dash_manifest.dart';
import '../../reverse_engineering/hls_manifest.dart';
import '../video_controller.dart';

class StreamController extends VideoController {
  StreamController(super.httpClient);

  Future<DashManifest> getDashManifest(String url) async {
    return DashManifest.parse(await httpClient.getString(url));
  }

  Future<HlsManifest> getHlsManifest(String url) async {
    return HlsManifest.parse(await httpClient.getString(url));
  }
}
