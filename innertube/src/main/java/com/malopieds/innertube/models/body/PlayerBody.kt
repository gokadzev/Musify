package com.malopieds.innertube.models.body

import com.malopieds.innertube.models.Context
import kotlinx.serialization.Serializable

@Serializable
data class PlayerBody(
    val context: Context,
    val videoId: String,
    val playlistId: String?,
    val cpn: String? = "wzf9Y0nqz6AUe2Vr", // need some random cpn to get same algorithm for sig
    val playbackContext: PlaybackContext? = PlaybackContext(ContentPlaybackContext(20052)),
) {
    @Serializable
    data class PlaybackContext(
        val contentPlaybackContext: ContentPlaybackContext?,
    )

    @Serializable
    data class ContentPlaybackContext(
        val signatureTimestamp: Int?,
    )
}
