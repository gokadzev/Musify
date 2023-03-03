import Flutter
import MediaPlayer

class PlaylistsQuery {
    // Main parameters
    private var args: [String: Any]
    private var result: FlutterResult?
    private var sink: FlutterEventSink?
    
    // Song projection (to filter).
    private let playlistProjection: [String?] = [
        "_id",
        nil,
        "date_added",
        "date_modified",
        "name"
    ]
    
    init(
        // Call from 'MethodChannel' (method).
        call: FlutterMethodCall? = nil,
        result: FlutterResult? = nil,
        // Call from 'EventChannel' (observer).
        sink: FlutterEventSink? = nil,
        args: [String: Any]? = nil
    ) {
        // Get all arguments inside the map.
        self.args = sink != nil ? args! : call!.arguments as! [String: Any]
        self.sink = sink
        self.result = result
    }
    
    func queryPlaylists() {
        // Choose the type(To match android side, let's call "cursor").
        let cursor = MPMediaQuery.playlists()
        
        // TODO: Add sort type to [queryPlaylists].
        
        // This filter will avoid audios/songs outside phone library(cloud).
        cursor.addFilterPredicate(MPMediaPropertyPredicate.init(
            value: false,
            forProperty: MPMediaItemPropertyIsCloudItem,
            comparisonType: .equalTo
        ))
        
        // Request permission status from the 'main' method.
        let hasPermission = SwiftOnAudioQueryPlugin().checkPermission()
        
        // We cannot 'query' without permission so, throw a PlatformException.
        // Only one 'channel' will be 'functional'. If is null, ignore, if not, send the error.
        if !hasPermission {
            // Method from 'EventChannel' (observer)
            self.sink?(
                FlutterError.init(
                    code: "403",
                    message: "The app doesn't have permission to read files.",
                    details: "Call the [permissionsRequest] method or install a external plugin to handle the app permission."
                )
            )
            
            // Method from 'MethodChannel' (method)
            self.result?(
                FlutterError.init(
                    code: "403",
                    message: "The app doesn't have permission to read files.",
                    details: "Call the [permissionsRequest] method or install a external plugin to handle the app permission."
                )
            )
            
            // 'Exit' the function
            return
        }
        
        // If [items] is null. Call early return with empty list.
        if cursor.collections == nil {
            // Empty list.
            self.sink?([])
            self.result?([])
            
            // 'Exit' the function.
            return
        }
        
        // Query everything in background for a better performance.
        DispatchQueue.global(qos: .userInitiated).async {
            var listOfPlaylists: [[String: Any?]] = Array()
            
            // Define the 'query' limit.
            let limit: Int? = self.args["limit"] as? Int
            
            // For each item(playlist) inside this "cursor", take one and "format"
            // into a [Map<String, dynamic>], all keys are based on [Android]
            // platforms so, if you change some key, will have to change the [Android] too.
            for playlist in cursor.collections! {
                // When list count reach the [limit]. Break the loop.
                //
                // If [limit] value is 'nil', continue.
                if listOfPlaylists.count == limit {
                    break
                }
                
                var playlistData = self.loadPlaylistItem(playlist: playlist)
                
                // If the first song file doesn't has a [assetURL], is probably a Cloud item.
                if !playlist.items.isEmpty && !playlist.items[0].isCloudItem && playlist.items[0].assetURL != nil {
                    // Count and add the number of songs for every genre.
                    let mediaCount = (playlistData["_id"] as! UInt64).getMediaCount(type: 1)
                    playlistData["num_of_songs"] = mediaCount
                } else {
                    playlistData["num_of_songs"] = 0
                }
                
                listOfPlaylists.append(playlistData)
            }
            
            // Define the [toQuery] and [toRemove] filter.
            let toQuery = self.args["toQuery"] as! [Int: [String]]
            let toRemove = self.args["toRemove"] as! [Int: [String]]
            
            // 'Build' the filter.
            listOfPlaylists = listOfPlaylists.mediaFilter(
                mediaProjection: self.playlistProjection,
                toQuery: toQuery,
                toRemove: toRemove
            )
            
            // After finish the "query", go back to the "main" thread(You can only call flutter
            // inside the main thread).
            DispatchQueue.main.async {
                // TODO: Add sort type to [queryPlaylists].
                
                // After loading the information, send the 'result'.
                self.sink?(listOfPlaylists)
                self.result?(listOfPlaylists)
            }
        }
    }
    
    private func loadPlaylistItem(playlist: MPMediaItemCollection) -> [String: Any?] {
        //Get the artwork from the first song inside the playlist
        var artwork: Data? = nil
        
        //
        if playlist.items.count >= 1 {
            artwork = playlist.items[0].artwork?.image(
                at: CGSize(width: 150, height: 150)
            )?.jpegData(compressionQuality: 1)
        }
        
        //
        let id = playlist.value(forProperty: MPMediaPlaylistPropertyPersistentID) as? Int
        let dateAdded = playlist.value(forProperty: "dateCreated") as? Date
        let dateModified = playlist.value(forProperty: "dateModified") as? Date
        
        //
        return [
            "_id": id,
            "name": playlist.value(forProperty: MPMediaPlaylistPropertyName),
            "date_added": Int(dateAdded!.timeIntervalSince1970),
            "date_modified": Int(dateModified!.timeIntervalSince1970),
            "number_of_tracks": playlist.items.count,
            "artwork": artwork
        ]
    }
}
