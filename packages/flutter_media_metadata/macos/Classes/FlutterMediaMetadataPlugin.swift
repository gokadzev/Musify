import Cocoa
import FlutterMacOS

public class FlutterMediaMetadataPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_media_metadata", binaryMessenger: registrar.messenger)
    let instance = FlutterMediaMetadataPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "MetadataRetriever":
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
