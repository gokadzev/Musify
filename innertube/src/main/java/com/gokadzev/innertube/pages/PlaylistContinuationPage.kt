package com.gokadzev.innertube.pages

import com.gokadzev.innertube.models.SongItem

data class PlaylistContinuationPage(
    val songs: List<SongItem>,
    val continuation: String?,
)
