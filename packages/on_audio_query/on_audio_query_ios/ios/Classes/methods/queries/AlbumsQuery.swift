import Flutter
import MediaPlayer

class AlbumsQuery {
    // Main parameters
    private var args: [String: Any]
    private var result: FlutterResult?
    private var sink: FlutterEventSink?
    
    // Album projection (to filter).
    private let albumProjection: [String?] = [
        "_id",
        "album",
        "artist",
        "artist_id",
        nil,
        nil,
        "numsongs",
        nil
    ]
    
    init(
        // Call from 'MethodChannel' (method).
        call: FlutterMethodCall? = nil,
        result: FlutterResult? = nil,
        // Call from 'EventChannel' (observer).
        sink: FlutterEventSink? = nil,
        args: [String: Any]? = nil
    ){
        // Get all arguments inside the map.
        self.args = sink != nil ? args! : call!.arguments as! [String: Any]
        self.sink = sink
        self.result = result
    }
    
    func queryAlbums() {
        // The sortType. If 'nil', will be set as [Album].
        let sortType = args["sortType"] as? Int ?? 0
        
        // Choose the type(To match android side, let's call "cursor").
        let cursor = MPMediaQuery.albums()
        
        // This filter will avoid audios/songs outside phone library(cloud).
        //
        // Sometimes this filter won't work.
        cursor.addFilterPredicate(MPMediaPropertyPredicate.init(
            value: false,
            forProperty: MPMediaItemPropertyIsCloudItem,
            comparisonType: .equalTo
        ))
        
        // Using native sort from [IOS] you can only use the [Album] and [Artist].
        // The others will be sorted "manually" using [formatAlbumList] before
        // sending to Dart.
        cursor.groupingType = checkAlbumSortType(sortType: sortType)
        
        // Request permission status from the 'main' method.
        let hasPermission = SwiftOnAudioQueryPlugin().checkPermission()
        
        // We cannot 'query' without permission so, throw a PlatformException.
        // Only one 'channel' will be 'functional'. If is null, ignore, if not, send the error.
        if !hasPermission {
            // Method from 'EventChannel' (observer).
            self.sink?(
                FlutterError.init(
                    code: "403",
                    message: "The app doesn't have permission to read files.",
                    details: "Call the [permissionsRequest] method or install a external plugin to handle the app permission."
                )
            )
            
            // Method from 'MethodChannel' (method).
            self.result?(
                FlutterError.init(
                    code: "403",
                    message: "The app doesn't have permission to read files.",
                    details: "Call the [permissionsRequest] method or install a external plugin to handle the app permission."
                )
            )
            
            // 'Exit' the function.
            return
        }
        
        // If [collections] is null. Call early return with empty list.
        if cursor.collections == nil {
            // Empty list.
            self.sink?([])
            self.result?([])
            
            // 'Exit' the function.
            return
        }
        
        // Query everything in background for a better performance.
        DispatchQueue.global(qos: .userInitiated).async {
            var listOfAlbums: [[String: Any?]] = Array()
            
            // Define the 'query' limit.
            let limit: Int? = self.args["limit"] as? Int
            
            // For each item(album) inside this "cursor", take one and "format"
            // into a [Map<String, dynamic>], all keys are based on [Android]
            // platforms so, if you change some key, will have to change the [Android] too.
            for album in cursor.collections! {
                // When list count reach the [limit]. Break the loop.
                //
                // If [limit] value is 'nil', continue.
                if listOfAlbums.count == limit {
                    break
                }
                
                if !album.items[0].isCloudItem && album.items[0].assetURL != nil {
                    let albumData = self.loadAlbumItem(album: album)
                    listOfAlbums.append(albumData)
                }
            }
            
            // Define the [toQuery] and [toRemove] filter.
            let toQuery = self.args["toQuery"] as! [Int: [String]]
            let toRemove = self.args["toRemove"] as! [Int: [String]]
            
            // 'Build' the filter.
            listOfAlbums = listOfAlbums.mediaFilter(
                mediaProjection: self.albumProjection,
                toQuery: toQuery,
                toRemove: toRemove
            )
            
            // After finish the "query", go back to the "main" thread(You can only call flutter
            // inside the main thread).
            DispatchQueue.main.async {
                // Here we'll check the "custom" sort and define a order to the list.
                let finalList = self.formatAlbumList(allAlbums: listOfAlbums)
                
                // After loading the information, send the 'result'.
                self.sink?(finalList)
                self.result?(finalList)
            }
        }
    }
    
    private func loadAlbumItem(album: MPMediaItemCollection) -> [String: Any?] {
        return [
            "numsongs": album.count,
            "artist": album.items[0].albumArtist,
            "_id": album.persistentID,
            "album": album.items[0].albumTitle,
            "artist_id": album.items[0].artistPersistentID,
            "album_id": album.items[0].albumPersistentID
        ]
    }

    private func formatAlbumList(allAlbums: [[String: Any?]]) -> [[String: Any?]] {
        // Define a copy of all albums.
        var allAlbumsCopy = allAlbums
        
        // Define all 'basic' filters.
        let order = args["orderType"] as? Int
        let sortType = args["sortType"] as? Int
        
        // Sort the list 'manually'.
        if sortType == 3 {
            allAlbumsCopy.sort { (val1, val2) -> Bool in
                (val1["numsongs"] as! Int) > (val2["numsongs"] as! Int)
            }
        }
        
        // The order value is [1], reverse the list.
        return order == 1 ? allAlbumsCopy.reversed() : allAlbumsCopy
    }
}
