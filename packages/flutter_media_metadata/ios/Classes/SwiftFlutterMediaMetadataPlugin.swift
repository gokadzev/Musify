import Flutter
import UIKit

public class SwiftFlutterMediaMetadataPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_media_metadata", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterMediaMetadataPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "MetadataRetriever" {
      guard let arguments = call.arguments as? [String: Any],
        let filePath = arguments["filePath"] as? String
      else {
        return
      }

      DispatchQueue.global().async {
        let retriever = MetadataRetriever(filePath)

        var response: [String: Any] = [:]
        response["metadata"] = retriever.getMetadata()
        response["albumArt"] = retriever.getAlbumArt()

        DispatchQueue.main.async {
          result(response)
        }
      }
    }
  }
}
