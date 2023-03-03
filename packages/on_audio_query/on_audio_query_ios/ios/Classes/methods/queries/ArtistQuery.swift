import Flutter
import MediaPlayer

class ArtistsQuery {
    // Main parameters
    private var args: [String: Any]
    private var result: FlutterResult?
    private var sink: FlutterEventSink?
    
    // Artist projection (to filter).
    private let artistProjection: [String?] = [
        "_id",
        "artists",
        "number_of_albums",
        "number_of_tracks"
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
    
    func queryArtists() {
        // Choose the type(To match android side, let's call "cursor").
        let cursor = MPMediaQuery.artists()
        
        // This filter will avoid audios/songs outside phone library(cloud).
        cursor.addFilterPredicate(MPMediaPropertyPredicate.init(
            value: false,
            forProperty: MPMediaItemPropertyIsCloudItem,
            comparisonType: .equalTo
        ))
        
        // We don't need to define a sortType here. [IOS] only support
        // the [Artist]. The others will be sorted "manually" using
        // [formatAudioList] before sending to Dart.
        
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
            var listOfArtists: [[String: Any?]] = Array()
            
            // Define the 'query' limit.
            let limit: Int? = self.args["limit"] as? Int
            
            // For each item(artist) inside this "cursor", take one and "format"
            // into a [Map<String, dynamic>], all keys are based on [Android]
            // platforms so, if you change some key, will have to change the [Android] too.
            for artist in cursor.collections! {
                // When list count reach the [limit]. Break the loop.
                //
                // If [limit] value is 'nil', continue.
                if listOfArtists.count == limit {
                    break
                }
                
                // If the first song file don't has a assetURL, is a Cloud item.
                if !artist.items[0].isCloudItem && artist.items[0].assetURL != nil {
                    let artistData = self.loadArtistItem(artist: artist)
                    listOfArtists.append(artistData)
                }
            }
            
            // Define the [toQuery] and [toRemove] filter.
            let toQuery = self.args["toQuery"] as! [Int: [String]]
            let toRemove = self.args["toRemove"] as! [Int: [String]]
            
            // 'Build' the filter.
            listOfArtists = listOfArtists.mediaFilter(
                mediaProjection: self.artistProjection,
                toQuery: toQuery,
                toRemove: toRemove
            )
            
            // After finish the "query", go back to the "main" thread(You can only call flutter
            // inside the main thread).
            DispatchQueue.main.async {
                // Here we'll check the "custom" sort and define a order to the list.
                let finalList = self.formatArtistList(allArtists: listOfArtists)
                
                // After loading the information, send the 'result'.
                self.sink?(finalList)
                self.result?(finalList)
            }
        }
    }
    
    private func loadArtistItem(artist: MPMediaItemCollection) -> [String: Any?] {
        // Get all albums.
        let albumsCursor = MPMediaQuery.albums()
        
        // Select only albums from 'this' artist.
        albumsCursor.addFilterPredicate(MPMediaPropertyPredicate.init(
            value: artist.items[0].albumArtist,
            forProperty: MPMediaItemPropertyAlbumArtist,
            comparisonType: .equalTo
        ))
        
        //
        var finalCount: [String] = Array()
        
        //
        let albums = albumsCursor.collections

        // Normally when the audio doesn't have a [album], will be defined as 'nil' or 'unknown',
        // So, we'll 'filter' the [albums], removing this 'non-albums'.
        //
        // If multiple audios does have the same [album], will be count only as 1.
        for album in albums! {
            // Use the [Title] as parameter.
            let itemAlbum = album.items[0].albumTitle
            
            //
            if itemAlbum != nil && !finalCount.contains(itemAlbum!) {
                finalCount.append(itemAlbum!)
            }
        }
        
        //
        return [
            "_id": artist.items[0].artistPersistentID,
            "artist": artist.items[0].artist,
            "number_of_albums": finalCount.count,
            "number_of_tracks": artist.count
        ]
    }

    private func formatArtistList(allArtists: [[String: Any?]]) -> [[String: Any?]] {
        // Define a copy of all artists.
        var allArtistsCopy = allArtists
        
        // Define all 'basic' filters.
        let order = args["orderType"] as? Int
        let sortType = args["sortType"] as? Int
        
        // Sort the list 'manually'.
        switch sortType {
        case 3:
            allArtistsCopy.sort { (val1, val2) -> Bool in
                (val1["number_of_tracks"] as! Int) > (val2["number_of_tracks"] as! Int)
            }
        case 4:
            allArtistsCopy.sort { (val1, val2) -> Bool in
                (val1["number_of_albums"] as! Int) > (val2["number_of_albums"] as! Int)
            }
        default:
            break
        }
        
        // The order value is [1], reverse the list.
        return order == 1 ? allArtistsCopy.reversed() : allArtistsCopy
    }
}
