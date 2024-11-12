package com.lucasjosino.on_audio_query.types.sorttypes

import android.provider.MediaStore

fun checkPlaylistSortType(sortType: Int?, order: Int, ignoreCase: Boolean): String {
    //[ASC] = Ascending Order
    //[DESC] = Descending Order
    //TODO: **Review this code later**
    val orderAndCase: String = if (ignoreCase) {
        if (order == 0) " COLLATE NOCASE ASC" else " COLLATE NOCASE DESC"
    } else {
        if (order == 0) " ASC" else " DESC"
    }
    return when (sortType) {
        0 -> MediaStore.Audio.Playlists.NAME + orderAndCase
        1 -> MediaStore.Audio.Playlists.DATE_ADDED + orderAndCase
        else -> MediaStore.Audio.Playlists.DEFAULT_SORT_ORDER + orderAndCase
    }
}