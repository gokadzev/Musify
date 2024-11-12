package com.lucasjosino.on_audio_query.consts

object Method {
    // General methods
    const val PERMISSION_STATUS = "permissionsStatus"
    const val PERMISSION_REQUEST = "permissionsRequest"
    const val QUERY_DEVICE_INFO = "queryDeviceInfo"
    const val SCAN = "scan"
    const val SET_LOG_CONFIG = "setLogConfig"

    // Query methods
    const val QUERY_AUDIOS = "querySongs"
    const val QUERY_ALBUMS = "queryAlbums"
    const val QUERY_ARTISTS = "queryArtists"
    const val QUERY_GENRES = "queryGenres"
    const val QUERY_PLAYLISTS = "queryPlaylists"
    const val QUERY_ARTWORK = "queryArtwork"
    const val QUERY_AUDIOS_FROM = "queryAudiosFrom"
    const val QUERY_WITH_FILTERS = "queryWithFilters"
    const val QUERY_ALL_PATHS = "queryAllPath"

    // Playlist methods
    const val CREATE_PLAYLIST = "createPlaylist"
    const val REMOVE_PLAYLIST = "removePlaylist"
    const val ADD_TO_PLAYLIST = "addToPlaylist"
    const val REMOVE_FROM_PLAYLIST = "removeFromPlaylist"
    const val RENAME_PLAYLIST = "renamePlaylist"
    const val MOVE_ITEM_TO = "moveItemTo"
}