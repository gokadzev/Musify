package com.gokadzev.musify.utils

import com.gokadzev.musify.db.entities.LyricsEntity

object TranslationHelper {
    suspend fun translate(lyrics: LyricsEntity): LyricsEntity = lyrics

    suspend fun clearModels() {}
}
