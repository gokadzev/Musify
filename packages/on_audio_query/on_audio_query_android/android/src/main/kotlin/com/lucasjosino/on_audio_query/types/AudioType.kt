package com.lucasjosino.on_audio_query.types

import android.os.Build
import android.provider.MediaStore

fun checkAudioType(type: Int): String {
    return when (type) {
        0 -> MediaStore.Audio.Media.IS_MUSIC
        1 -> MediaStore.Audio.Media.IS_ALARM
        2 -> MediaStore.Audio.Media.IS_NOTIFICATION
        3 -> MediaStore.Audio.Media.IS_PODCAST
        4 -> MediaStore.Audio.Media.IS_RINGTONE
        //
        5 -> if (Build.VERSION.SDK_INT > 29) MediaStore.Audio.Media.IS_AUDIOBOOK else ""
        else -> throw Exception("[checkAudioType] value doesn't exist!")
    }
}