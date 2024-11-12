package com.lucasjosino.on_audio_query.types.sorttypes

import android.provider.MediaStore

fun checkGenreSortType(sortType: Int?, order: Int, ignoreCase: Boolean): String {
    //[ASC] = Ascending Order
    //[DESC] = Descending Order
    //TODO: **Review this code later**
    val orderAndCase: String = if (ignoreCase) {
        if (order == 0) " COLLATE NOCASE ASC" else " COLLATE NOCASE DESC"
    } else {
        if (order == 0) " ASC" else " DESC"
    }
    return when (sortType) {
        0 -> MediaStore.Audio.Genres.NAME + orderAndCase
        else -> MediaStore.Audio.Genres.DEFAULT_SORT_ORDER + orderAndCase
    }
}