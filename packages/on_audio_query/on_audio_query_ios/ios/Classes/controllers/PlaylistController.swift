import Flutter
import MediaPlayer

class PlaylistsController {
    var args: [String: Any]
    var result: FlutterResult
    
    init(call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.args = call.arguments as! [String: Any]
        self.result = result
    }
    
    // Due the [IOS] limitation, for now we can only create/add to playlists.
    func createPlaylist() {
        // The name, author and description for playlist, playlistName cannot be null.
        let playlistName = args["playlistName"] as! String
        let playlistAuthor = args["playlistAuthor"] as? String
        let playlistDesc = args["playlistDesc"] as? String
        
        //
        let playlistMetadata = MPMediaPlaylistCreationMetadata.init(name: playlistName)
        playlistMetadata.authorDisplayName = playlistAuthor
        playlistMetadata.descriptionText = playlistDesc ?? ""
        
        //
        MPMediaLibrary().getPlaylist(with: UUID.init(), creationMetadata: playlistMetadata, completionHandler: { playlist, error in
            //A little second to create the playlist and Flutter UI update
            sleep(1)
            if playlist != nil {
                self.result(true)
            } else {
                print(error ?? "Something wrong happend")
                self.result(false)
            }
        }
        )
    }
    
    func addToPlaylist() {
        //
        let playlistId = args["playlistId"] as! Int
        let audioId = args["audioId"] as! Int
        
        // TODO: Use another method to get UUID from playlist
        //
        // Link: https://github.com/HumApp/MusicKit/blob/master/AppleMusicSample/Controllers/MediaLibraryManager.swift
        let playlist: MPMediaPlaylist? = loadPlaylist(id: playlistId)
        
        // [addItem] won't work in the main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            var hasAdded: Bool = false
            
            // If playlist is null, just return [false].
            if playlist != nil {
                playlist!.addItem(withProductID: String(audioId), completionHandler: { error in
                    if error == nil {
                        hasAdded = true
                    } else {
                        hasAdded = false
                        // TODO: Fix "NSLocalizedDescription=The requested operation is not enabled for this device."
                        print("on_audio_error: " + error.debugDescription)
                    }
                })
            } else {
                hasAdded = false
            }
            
            DispatchQueue.main.async {
                self.result(hasAdded)
            }
        }
    }
    
    private func loadPlaylist(id: Int) -> MPMediaPlaylist? {
        let cursor = MPMediaQuery.playlists()
        
        //
        let playlistFilter = MPMediaPropertyPredicate.init(value: id, forProperty: MPMediaPlaylistPropertyPersistentID)
        let noCloudItemFilter = MPMediaPropertyPredicate.init(value: false, forProperty: MPMediaItemPropertyIsCloudItem)
        cursor.addFilterPredicate(playlistFilter)
        cursor.addFilterPredicate(noCloudItemFilter)
        
        let firstPlaylist = cursor.collections?.first as? MPMediaPlaylist
        return firstPlaylist
    }
}
