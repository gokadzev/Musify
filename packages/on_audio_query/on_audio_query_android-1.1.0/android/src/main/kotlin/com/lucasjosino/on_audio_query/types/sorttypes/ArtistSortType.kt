package com.lucasjosino.on_audio_query.types.sorttypes

import android.provider.MediaStore

fun checkArtistSortType(sortType: Int?, order: Int, ignoreCase: Boolean): String {
    //[ASC] = Ascending Order
    //[DESC] = Descending Order
    //TODO: **Review this code later**
    val orderAndCase: String = if (ignoreCase) {
        if (order == 0) " COLLATE NOCASE ASC" else " COLLATE NOCASE DESC"
    } else {
        if (order == 0) " ASC" else " DESC"
    }
    return when (sortType) {
        0 -> MediaStore.Audio.Artists.ARTIST + orderAndCase
        1 -> MediaStore.Audio.Artists.NUMBER_OF_TRACKS + orderAndCase
        2 -> MediaStore.Audio.Artists.NUMBER_OF_ALBUMS + orderAndCase
        else -> MediaStore.Audio.Artists.DEFAULT_SORT_ORDER + orderAndCase
    }
}