package com.lucasjosino.on_audio_query.types.sorttypes

import android.annotation.SuppressLint
import android.provider.MediaStore

@SuppressLint("InlinedApi")
fun checkSongSortType(sortType: Int?, order: Int, ignoreCase: Boolean): String {
    //[ASC] = Ascending Order
    //[DESC] = Descending Order
    //TODO: **Review this code later**
    val orderAndCase: String = if (ignoreCase) {
        if (order == 0) " COLLATE NOCASE ASC" else " COLLATE NOCASE DESC"
    } else {
        if (order == 0) " ASC" else " DESC"
    }
    return when (sortType) {
        0 -> MediaStore.Audio.Media.TITLE + orderAndCase
        1 -> MediaStore.Audio.Media.ARTIST + orderAndCase
        2 -> MediaStore.Audio.Media.ALBUM + orderAndCase
        3 -> MediaStore.Audio.Media.DURATION + orderAndCase
        4 -> MediaStore.Audio.Media.DATE_ADDED + orderAndCase
        5 -> MediaStore.Audio.Media.SIZE + orderAndCase
        6 -> MediaStore.Audio.Media.DISPLAY_NAME + orderAndCase
        else -> MediaStore.Audio.Media.DEFAULT_SORT_ORDER + orderAndCase
    }
}