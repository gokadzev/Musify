import Flutter

public class QueryController {
    var call: FlutterMethodCall
    var result: FlutterResult
    
    init(call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.call = call
        self.result = result
    }
    
    //This method will sort call according to request.
    public func chooseMethod() {
        // All necessary method to this plugin support both platforms, only playlists
        // are limited when using [IOS].
        switch call.method {
        case "queryAudios":
            AudiosQuery(call: call, result: result).queryAudios()
        case "queryAlbums":
            AlbumsQuery(call: call, result: result).queryAlbums()
        case "queryArtists":
            ArtistsQuery(call: call, result: result).queryArtists()
        case "queryGenres":
            GenresQuery(call: call, result: result).queryGenres()
        case "queryPlaylists":
            PlaylistsQuery(call: call, result: result).queryPlaylists()
        case "queryArtwork":
            ArtworkQuery(call: call, result: result).queryArtwork()
        // The playlist for [IOS] is completely limited, the developer can only:
        //   * Create playlist
        //   * Add item to playlist (Unsuported, for now)
        //
        // Missing methods:
        //   * Rename playlist
        //   * Remove playlist
        //   * Remove item from playlist
        //   * Move item inside playlist
        case "createPlaylist":
            PlaylistsController(call: call, result: result).createPlaylist()
        case "addToPlaylist":
            PlaylistsController(call: call, result: result).addToPlaylist()
        default:
            // All non suported methods will throw this error.
            result(FlutterMethodNotImplemented)
        }
    }
}
