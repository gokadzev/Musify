package com.gokadzev.musify.lyrics

import android.content.Context
import com.gokadzev.musify.constants.EnableKugouKey
import com.gokadzev.musify.utils.dataStore
import com.gokadzev.musify.utils.get
import com.gokadzev.kugou.KuGou

object KuGouLyricsProvider : LyricsProvider {
    override val name = "Kugou"

    override fun isEnabled(context: Context): Boolean = context.dataStore[EnableKugouKey] ?: true

    override suspend fun getLyrics(
        id: String,
        title: String,
        artist: String,
        duration: Int,
    ): Result<String> = KuGou.getLyrics(title, artist, duration)

    override suspend fun getAllLyrics(
        id: String,
        title: String,
        artist: String,
        duration: Int,
        callback: (String) -> Unit,
    ) {
        KuGou.getAllLyrics(title, artist, duration, callback)
    }
}
