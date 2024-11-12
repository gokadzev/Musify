package com.lucasjosino.on_audio_query.utils

import android.annotation.SuppressLint
import android.os.Build
import android.provider.MediaStore

// Query songs projection
@SuppressLint("InlinedApi")
// Ignore the [Data] deprecation because this plugin support older versions.
@Suppress("DEPRECATION")
fun songProjection(): Array<String> {
    val tmpProjection = arrayListOf(
        MediaStore.Audio.Media.DATA, // TODO: Deprecated
        MediaStore.Audio.Media.DISPLAY_NAME,
        MediaStore.Audio.Media._ID,
        MediaStore.Audio.Media.SIZE,
        MediaStore.Audio.Media.ALBUM,
        MediaStore.Audio.Media.ALBUM_ARTIST,
        MediaStore.Audio.Media.ALBUM_ID,
        MediaStore.Audio.Media.ARTIST,
        MediaStore.Audio.Media.ARTIST_ID,
        MediaStore.Audio.Media.BOOKMARK,
        MediaStore.Audio.Media.COMPOSER,
        MediaStore.Audio.Media.DATE_ADDED,
        MediaStore.Audio.Media.DATE_MODIFIED,
        MediaStore.Audio.Media.DURATION,
        MediaStore.Audio.Media.TITLE,
        MediaStore.Audio.Media.TRACK,
        MediaStore.Audio.Media.YEAR,
        MediaStore.Audio.Media.IS_ALARM,
        MediaStore.Audio.Media.IS_MUSIC,
        MediaStore.Audio.Media.IS_NOTIFICATION,
        MediaStore.Audio.Media.IS_PODCAST,
        MediaStore.Audio.Media.IS_RINGTONE,
    )

    if (Build.VERSION.SDK_INT >= 29) {
        tmpProjection.add(MediaStore.Audio.Media.IS_AUDIOBOOK) // Only Api >= 29
    }

    if (Build.VERSION.SDK_INT >= 30) {
        tmpProjection.add(MediaStore.Audio.Media.GENRE) // Only Api >= 30
        tmpProjection.add(MediaStore.Audio.Media.GENRE_ID) // Only Api >= 30
    }

    return tmpProjection.toTypedArray()
}


// Query playlists projection
// Ignore the [Data] deprecation because this plugin support older versions.
@Suppress("DEPRECATION")
val playlistProjection = arrayOf(
    MediaStore.Audio.Playlists.DATA,
    MediaStore.Audio.Playlists._ID,
    MediaStore.Audio.Playlists.DATE_ADDED,
    MediaStore.Audio.Playlists.DATE_MODIFIED,
    MediaStore.Audio.Playlists.NAME
)

//Query artists projection
val artistProjection = arrayOf(
    MediaStore.Audio.Artists._ID,
    MediaStore.Audio.Artists.ARTIST,
    MediaStore.Audio.Artists.NUMBER_OF_ALBUMS,
    MediaStore.Audio.Artists.NUMBER_OF_TRACKS
)

//Query genres projection
val genreProjection = arrayOf(
    MediaStore.Audio.Genres._ID,
    MediaStore.Audio.Genres.NAME
)