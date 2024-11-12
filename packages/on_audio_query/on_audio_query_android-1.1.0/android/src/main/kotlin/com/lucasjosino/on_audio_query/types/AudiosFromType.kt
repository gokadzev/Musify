package com.lucasjosino.on_audio_query.types

import android.annotation.SuppressLint
import android.provider.MediaStore

@SuppressLint("InlinedApi")
fun checkAudiosFromType(sortType: Int): String {
    return when (sortType) {
        0 -> MediaStore.Audio.Media.ALBUM + " like ?"
        1 -> MediaStore.Audio.Media.ALBUM_ID + " like ?"
        2 -> MediaStore.Audio.Media.ARTIST + " like ?"
        3 -> MediaStore.Audio.Media.ARTIST_ID + " like ?"
        // Use the [TRIM] to remove all empty space from genre name.
        4 -> "TRIM(\"" + MediaStore.Audio.Media.GENRE + "\")" + " like ?"
        5 -> MediaStore.Audio.Media.GENRE_ID + " like ?"
        else -> throw Exception("[checkAudiosFromType] value don't exist!")
    }
}