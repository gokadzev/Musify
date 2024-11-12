package com.lucasjosino.on_audio_query.controllers

import com.lucasjosino.on_audio_query.PluginProvider
import com.lucasjosino.on_audio_query.consts.Method
import com.lucasjosino.on_audio_query.queries.*

class MethodController() {

    //
    fun find() {
        when (PluginProvider.call().method) {
            //Query methods
            Method.QUERY_AUDIOS -> AudioQuery().querySongs()
            Method.QUERY_ALBUMS -> AlbumQuery().queryAlbums()
            Method.QUERY_ARTISTS -> ArtistQuery().queryArtists()
            Method.QUERY_PLAYLISTS -> PlaylistQuery().queryPlaylists()
            Method.QUERY_GENRES -> GenreQuery().queryGenres()
            Method.QUERY_ARTWORK -> ArtworkQuery().queryArtwork()
            Method.QUERY_AUDIOS_FROM -> AudioFromQuery().querySongsFrom()
            Method.QUERY_WITH_FILTERS -> WithFiltersQuery().queryWithFilters()
            Method.QUERY_ALL_PATHS -> AllPathQuery().queryAllPath()
            //Playlists methods
            Method.CREATE_PLAYLIST -> PlaylistController().createPlaylist()
            Method.REMOVE_PLAYLIST -> PlaylistController().removePlaylist()
            Method.ADD_TO_PLAYLIST -> PlaylistController().addToPlaylist()
            Method.REMOVE_FROM_PLAYLIST -> PlaylistController().removeFromPlaylist()
            Method.RENAME_PLAYLIST -> PlaylistController().renamePlaylist()
            Method.MOVE_ITEM_TO -> PlaylistController().moveItemTo()
            else -> PluginProvider.result().notImplemented()
        }
    }
}