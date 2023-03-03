import Flutter
import MediaPlayer

class AudiosQuery {
    // Main parameters
    private var args: [String: Any]
    private var result: FlutterResult?
    private var sink: FlutterEventSink?
    
    // Audio projection (to filter).
    private let audioProjection: [String?] = [
        "_id",
        "_data",
        "_display_name",
        nil,
        "album",
        nil,
        "album_id",
        "artist",
        "artist_id",
        nil,
        "composer",
        nil,
        nil,
        nil,
        "title",
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
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
        self.args = sink != nil ? args! : (call!.arguments as! [String: Any])
        self.sink = sink
        self.result = result
    }
    
    func queryAudios() {
        // The sortType. If 'nil', will be set as [Title].
        let sortType = args["sortType"] as? Int ?? 0
        
        // Define the query (To match android side, let's call "cursor").
        let cursor: MPMediaQuery = MPMediaQuery.init()
    
        // This filter will avoid audios/songs outside phone library(cloud).
        //
        // Sometimes this filter won't work.
        cursor.addFilterPredicate(MPMediaPropertyPredicate.init(
            value: false,
            forProperty: MPMediaItemPropertyIsCloudItem,
            comparisonType: .equalTo
        ))
        
        // Using native sort from [IOS] you can only use the [Title], [Album] and
        // [Artist]. The others will be sorted 'manually' using [formatAudioList] before
        // sending to Dart.
        cursor.groupingType = checkAudioSortType(sortType: sortType)
        
        // Request permission status from the 'main' method.
        let hasPermission = SwiftOnAudioQueryPlugin().checkPermission()
        
        // We cannot 'query' without permission so, throw a PlatformException.
        // Only one 'channel' will be 'functional'. If is null, ignore, if not, send the error.
        if !hasPermission {
            // Call from 'EventChannel' (observer)
            self.sink?(
                FlutterError.init(
                    code: "403",
                    message: "The app doesn't have permission to read files.",
                    details: "Call the [permissionsRequest] method or install a external plugin to handle the app permission."
                )
            )
            
            // Call from 'MethodChannel' (method)
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
        
        // Define the 'new' items.
        var cursorItems: [MPMediaItem] = []
        
        // Get all defined types.
        let types = args["type"] as! [Int: Int]
        
        // TODO: Can 'MPMediaQuery' support differents [values] to the same [property]?
        // TODO: Add ringtones
        // https://github.com/CQH/iOS-Sounds-and-Ringtones/blob/master/iOS%20Sounds%20and%20Ringtones/DirectoriesTableViewController.swift#L85
        
        // To support others audios type we need a 'workaround'.
        //
        // Define the filter [type], get the audio list, add to the [cursorItems]
        // and remove the filter.
        for (type, _) in types {
            // Define the current filter.
            let currentFilter = MPMediaPropertyPredicate.init(
                value: checkAudioType(sortType: type),
                forProperty: MPMediaItemPropertyMediaType,
                comparisonType: .equalTo
            )
            
            // Add the filter to the 'cursor'.
            cursor.addFilterPredicate(currentFilter)
            
            // Get this list and 'append' to another list.
            cursorItems.append(contentsOf: cursor.items ?? [])
            
            // Remove the filter.
            cursor.removeFilterPredicate(currentFilter)
        }
        
        // Query everything in background for a better performance.
        DispatchQueue.global(qos: .userInitiated).async {
            var listOfAudios: [[String: Any?]] = Array()
            
            // Define the 'query' limit.
            let limit: Int? = self.args["limit"] as? Int
            
            // For each item(audio) inside this "cursor", take one and "format"
            // into a [Map<String, dynamic>], all keys are based on [Android]
            // platforms so, if you change some key, will have to change the [Android] too.
            for audio in cursorItems {
                // When list count reach the [limit]. Break the loop.
                //
                // If [limit] value is 'nil', continue.
                if listOfAudios.count == limit {
                    break
                }
                
                // If the audio file don't has a assetURL, is a Cloud item.
                if !audio.isCloudItem && audio.assetURL != nil {
                    let audioData = self.loadAudioItem(audio: audio)
                    listOfAudios.append(audioData)
                }
            }
            
            // Define the [toQuery] and [toRemove] filter.
            let toQuery = self.args["toQuery"] as! [Int: [String]]
            let toRemove = self.args["toRemove"] as! [Int: [String]]
            
            // 'Build' the filter.
            listOfAudios = listOfAudios.mediaFilter(
                mediaProjection: self.audioProjection,
                toQuery: toQuery,
                toRemove: toRemove
            )
            
            // After finish the "query", go back to the "main" thread(You can only call flutter
            // inside the main thread).
            DispatchQueue.main.async {
                // Here we'll check the "custom" sort and define a order to the list.
                let finalList = self.formatAudioList(allAudios: listOfAudios)
                
                // After loading the information, send the 'result'.
                self.sink?(finalList)
                self.result?(finalList)
            }
        }
    }
    
    private func loadAudioItem(audio: MPMediaItem) -> [String: Any?] {
        let fileExt = audio.assetURL?.pathExtension ?? ""
        let sizeInBytes = audio.value(forProperty: "fileSize") as? Int
        return [
            "_id": audio.persistentID,
            "_data": audio.assetURL?.absoluteString,
            "_uri": audio.assetURL?.absoluteString,
            "_display_name": "\(audio.artist ?? "") - \(audio.title ?? "").\(fileExt)",
            "_display_name_wo_ext": "\(audio.artist ?? "") - \(audio.title ?? "")",
            "_size": sizeInBytes,
            "audio_id": nil,
            "album": audio.albumTitle,
            "album_id": audio.albumPersistentID,
            "artist": audio.artist,
            "artist_id": audio.artistPersistentID,
            "genre": audio.genre,
            "genre_id": audio.genrePersistentID,
            "bookmark": Int(audio.bookmarkTime),
            "composer": audio.composer,
            "date_added": Int(audio.dateAdded.timeIntervalSince1970),
            "date_modified": 0,
            "duration": Int(audio.playbackDuration * 1000),
            "title": audio.title,
            "track": audio.albumTrackNumber,
            "file_extension": fileExt,
        ]
    }
    
    private func formatAudioList(allAudios: [[String: Any?]]) -> [[String: Any?]] {
        // Define a copy of all audios.
        var allAudiosCopy = allAudios
        
        // Define all 'basic' filters.
        let order = args["orderType"] as? Int
        let sortType = args["sortType"] as? Int
        let ignoreCase = args["ignoreCase"] as! Bool
        
        // Sort the list 'manually'.
        switch sortType {
        case 3:
            allAudiosCopy.sort { (val1, val2) in
                (val1["duration"] as! Double) > (val2["duration"] as! Double)
            }
        case 4:
            allAudiosCopy.sort { (val1, val2) in
                (val1["date_added"] as! Int) > (val2["date_added"] as! Int)
            }
        case 5:
            allAudiosCopy.sort { (val1, val2) in
                (val1["_size"] as! Int) > (val2["_size"] as! Int)
            }
        case 6:
            allAudiosCopy.sort { (val1, val2) in
                ((val1["_display_name"] as! String).isCase(ignoreCase: ignoreCase)) > ((val2["_display_name"] as! String).isCase(ignoreCase: ignoreCase))
            }
        case 7:
            allAudiosCopy.sort { (val1, val2) in
                (val1["track"] as! Int) > (val2["track"] as! Int)
            }
        default:
            break
        }
        
        // The order value is [1], reverse the list.
        return order == 1 ? allAudiosCopy.reversed() : allAudiosCopy
    }
}
