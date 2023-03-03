import Flutter
import MediaPlayer

class ArtworkQuery {
    
    private let pluginDir = "/on_audio_query/mediastore/artworks/"
    
    private var args: [String: Any]
    private var result: FlutterResult
    
    init(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // To make life easy, add all arguments inside a map.
        self.args = call.arguments as! [String: Any]
        self.result = result
    }
    
    // [IOS] has a different artwork system and you can "query" using normal "queryAudios, .."
    // [Android] can't "query" artwork at the same time as "queryAudios", so we need to "query"
    // using a different method(queryArtwork).
    //
    // To match both [IOS] and [Android], [queryArtwork] is the only way to get artwork.
    //
    // Not the best solution but, at least here we can select differents formats and size.
    func queryArtwork() {
        // None of this arguments can be null.
        // The id of the [Audio] or [Album].
        let id = args["id"] as! Int
        
        // The uri [0]: Audio and [1]: Album.
        let uri = args["type"] as! Int
        
        // (To match android side, let's call "cursor").
        var cursor: MPMediaQuery?
        var filter: MPMediaPropertyPredicate?
        
        // If [uri] is 0: artwork from [Audio]
        // If [uri] is 1: artwork from [Album]
        // If [uri] is 2: artwork from [Playlist]
        // If [uri] is 3: artwork from [Artist]
        switch uri {
        case 0:
            filter = MPMediaPropertyPredicate.init(value: id, forProperty: MPMediaItemPropertyPersistentID)
            cursor = MPMediaQuery.songs()
        case 1:
            filter = MPMediaPropertyPredicate.init(value: id, forProperty: MPMediaItemPropertyAlbumPersistentID)
            cursor = MPMediaQuery.albums()
        case 2:
            filter = MPMediaPropertyPredicate.init(value: id, forProperty: MPMediaPlaylistPropertyPersistentID)
            cursor = MPMediaQuery.playlists()
        case 3:
            filter = MPMediaPropertyPredicate.init(value: id, forProperty: MPMediaItemPropertyArtistPersistentID)
            cursor = MPMediaQuery.artists()
        case 4:
            filter = MPMediaPropertyPredicate.init(value: id, forProperty: MPMediaItemPropertyGenrePersistentID)
            cursor = MPMediaQuery.genres()
        default:
            filter = nil
            cursor = nil
        }
        
        // Request permission status from the 'main' method.
        let hasPermission = SwiftOnAudioQueryPlugin().checkPermission()
        
        // We cannot 'query' without permission so, throw a PlatformException.
        if !hasPermission {
            // Method from 'MethodChannel' (method)
            self.result(
                FlutterError.init(
                    code: "403",
                    message: "The app doesn't have permission to read files.",
                    details: "Call the [permissionsRequest] method or install a external plugin to handle the app permission."
                )
            )
            
            // 'Exit' the function
            return
        }
        
        //
        if cursor != nil && filter != nil {
            cursor?.addFilterPredicate(filter!)
            
            // This filter will avoid audios/songs outside phone library(cloud).
            let cloudFilter = MPMediaPropertyPredicate.init(
                value: false,
                forProperty: MPMediaItemPropertyIsCloudItem
            )
            cursor?.addFilterPredicate(cloudFilter)
            
            // Query everything in background for a better performance.
            loadArtwork(cursor: cursor, id: id, uri: uri)
        } else {
            // Return to Flutter
            result(nil)
        }
    }
    
    private func loadArtwork(cursor: MPMediaQuery!, id: Int, uri: Int) {
        // The size of the image.
        let size = args["size"] as! Int
        
        // The size of the image.
        var quality = args["quality"] as! Int
        if (quality > 100) {
            quality = 50
        }
        
        // The format [JPEG] or [PNG].
        let format = args["format"] as! Int
        
        DispatchQueue.global(qos: .userInitiated).async {
            var artwork: Data?
            var item: MPMediaItem?
            let fixedQuality = CGFloat(Double(quality) / 100.0)
            
            // If [uri] is 0: artwork is from [Audio]
            // If [uri] is 1, 2 or 3: artwork is from [Album], [Playlist] or [Artist]
            if uri == 0 {
                // Since all id are unique, we can safely call the first item.
                item = cursor!.items?.first
            } else {
                // Since all id are unique, we can safely call the first item.
                item = cursor!.collections?.first?.items.first
            }
            
            // If [format] is 0: will be [JPEG]
            // If [format] is 1: will be [PNG]
            if format == 0 {
                artwork = item?.artwork?.image(at: CGSize(width: size, height: size))?.jpegData(compressionQuality: fixedQuality)
            } else {
                // [PNG] format will return a high image quality.
                artwork = item?.artwork?.image(at: CGSize(width: size, height: size))?.pngData()
            }
            
            // After finish the "query", go back to the "main" thread(You can only call flutter
            // inside the main thread).
            DispatchQueue.main.async {
                // We don't need a "empty" image so, return null to avoid problems.
                if artwork != nil && artwork!.isEmpty {
                    artwork = nil
                }
                
                // Define the value to cache or no the artwork inside the app dir.
                let cacheArtwork = self.args["cacheArtwork"] as! Bool
                
                // This parameter will only be defined if [cacheArtwork] is true and
                // the artwork can be cached.
                var artPath: String? = nil
                
                // Check the value of artwork and if we need to 'cache'.
                if artwork != nil && cacheArtwork {
                    artPath = self.cacheArtwork(format: format, artwork: artwork!)
                }
                
                // Send the result.
                self.result(
                    [
                        "_id": id,
                        "artwork": artwork as Any,
                        "path": artPath as Any,
                        "type": format == 0 ? "JPEG" : "PNG"
                    ]
                )
            }
        }
    }
    
    private func cacheArtwork(format: Int, artwork: Data) -> String? {
        // The file type.
        var fileType: String
        
        // Check the file type.
        if format == 0 {
            fileType = ".jpeg"
        } else {
            fileType = ".png"
        }
        
        // All artworks will be 'cached' with audio/album/artist/playlist
        // or genre [id] and the artwork [type].
        let fileName = String((args["id"] as! Int)) + fileType
        
        // Define if the artwork will be saved in a tmp folder.
        let cacheTemporarily = args["cacheTemporarily"] as! Bool
        let dirType: FileManager.SearchPathDirectory
        
        if cacheTemporarily {
            dirType = FileManager.SearchPathDirectory.cachesDirectory
        } else {
            dirType = FileManager.SearchPathDirectory.documentDirectory
        }
        
        // Define if the file will be overwritten.
        let overrideCache = args["overrideCache"] as! Bool
        
        // Check if the specified directory exists.
        if let dir: String = NSSearchPathForDirectoriesInDomains(
            dirType,
            .userDomainMask,
            true
        ).first {
            // Join the specific app dir with the plugin dir and check if
            // the directory exists.
            if var pathUrl = URL(string: dir + pluginDir) {
                
                // Check if the artwork already exist.
                let fileExists = FileManager.default.fileExists(
                    atPath: pathUrl.absoluteString + fileName
                )
                
                // If [overrideCache] is true the artwork will be overwritten.
                //
                // If [overrideCache] is false and the file already exists, return
                // the path to this artwork.
                if !overrideCache && fileExists {
                    return pathUrl.absoluteString
                }
                
                // Create the plugin directory if is none.
                if !FileManager.default.fileExists(atPath: pathUrl.absoluteString) {
                    do {
                        try FileManager.default.createDirectory(
                            atPath: pathUrl.absoluteString,
                            withIntermediateDirectories: true,
                            attributes: nil
                        )
                    } catch {
                        print("ArtworkQuery::cacheArtwork(fileExists) -> \(error)")
                    }
                }
                
                // Now the the file dir and define a new file(artwork).
                pathUrl.appendPathComponent(fileName)
                
                // Add a 'file:' schema to url.
                let fixedPath = URL(fileURLWithPath: pathUrl.absoluteString)
                
                // Try write the artwork.
                do {
                    // Try to write the file.
                    try artwork.write(to: fixedPath, options: Data.WritingOptions.atomic)
                    
                    // Return the path to this artwork.
                    return pathUrl.absoluteString
                } catch {
                    print("ArtworkQuery::cacheArtwork(write) -> \(error)")
                }
            }
        }
        
        // If anything goes wrong, return nil.
        return nil
    }
}
