import Flutter
import MediaPlayer

class GenresQuery {
    // Main parameters
    private var args: [String: Any]
    private var result: FlutterResult?
    private var sink: FlutterEventSink?
    
    // Genre projection (to filter).
    private let genreProjection: [String?] = [
        "_id",
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
    
    func queryGenres() {
        // Choose the type(To match android side, let's call "cursor").
        let cursor = MPMediaQuery.genres()
        
        // This filter will avoid audios/songs outside phone library(cloud).
        cursor.addFilterPredicate(MPMediaPropertyPredicate.init(
            value: false,
            forProperty: MPMediaItemPropertyIsCloudItem,
            comparisonType: .equalTo
        ))
        
        // We don't need to define a sortType here. [IOS] only support
        // the [Artist]. The others will be sorted "manually" using
        // [formatSongList] before send to Dart.
        
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
            var listOfGenres: [[String: Any?]] = Array()
            
            // Define the 'query' limit.
            let limit: Int? = self.args["limit"] as? Int
            
            // For each item(genre) inside this "cursor", take one and "format"
            // into a [Map<String, dynamic>], all keys are based on [Android]
            // platforms so, if you change some key, will have to change the [Android] too.
            for genre in cursor.collections! {
                // When list count reach the [limit]. Break the loop.
                //
                // If [limit] value is 'nil', continue.
                if listOfGenres.count == limit {
                    break
                }
                
                if !genre.items[0].isCloudItem && genre.items[0].assetURL != nil {
                    var genreData = self.loadGenreItem(genre: genre)
                    
                    // Count and add the number of songs for every genre.
                    let mediaCount = (genreData["_id"] as! UInt64).getMediaCount(type: 0)
                    genreData["num_of_songs"] = mediaCount
                    
                    listOfGenres.append(genreData)
                }
            }
            
            // Define the [toQuery] and [toRemove] filter.
            let toQuery = self.args["toQuery"] as! [Int: [String]]
            let toRemove = self.args["toRemove"] as! [Int: [String]]
            
            // 'Build' the filter.
            listOfGenres = listOfGenres.mediaFilter(
                mediaProjection: self.genreProjection,
                toQuery: toQuery,
                toRemove: toRemove
            )
            
            // After finish the "query", go back to the "main" thread(You can only call flutter
            // inside the main thread).
            DispatchQueue.main.async {
                // Here we'll check the "custom" sort and define a order to the list.
                let finalList = self.formatGenreList(allGenres: listOfGenres)
                
                // After loading the information, send the 'result'.
                self.sink?(finalList)
                self.result?(finalList)
            }
        }
    }
    
    private func loadGenreItem(genre: MPMediaItemCollection) -> [String: Any?] {
        return [
            "_id": genre.items[0].genrePersistentID,
            "name": genre.items[0].genre,
            "number_of_songs": genre.count
        ]
    }

    private func formatGenreList(allGenres: [[String: Any?]]) -> [[String: Any?]] {
        // Define a copy of all songs.
        let allGenresCopy = allGenres
        
        // Define all 'basic' filters.
        let order = args["orderType"] as? Int
        
        // The order value is [1], reverse the list.
        return order == 1 ? allGenresCopy.reversed() : allGenresCopy
    }
}
