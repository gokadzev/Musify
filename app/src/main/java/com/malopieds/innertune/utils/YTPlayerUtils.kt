package com.malopieds.innertune.utils

import android.net.ConnectivityManager
import androidx.media3.common.PlaybackException
import com.malopieds.innertube.YouTube
import com.malopieds.innertube.models.YouTubeClient
import com.malopieds.innertube.models.YouTubeClient.Companion.IOS
import com.malopieds.innertube.models.YouTubeClient.Companion.MAIN_CLIENT
import com.malopieds.innertube.models.YouTubeClient.Companion.TVHTML5
import com.malopieds.innertube.models.response.PlayerResponse
import com.malopieds.innertube.utils.NewPipeUtils
import com.malopieds.innertune.constants.AudioQuality
import com.malopieds.innertune.db.entities.FormatEntity
import okhttp3.OkHttpClient

object YTPlayerUtils {

    private val httpClient = OkHttpClient.Builder()
        .proxy(YouTube.proxy)
        .build()

    /**
     * The main client is used for metadata and initial streams.
     * Do not use other clients for this because it can result in inconsistent metadata.
     * For example other clients can have different normalization targets (loudnessDb).
     *
     * [com.malopieds.innertube.models.YouTubeClient.WEB_REMIX] should be preferred here because currently
     * it is the only client which provides:
     * - the correct metadata (like loudnessDb)
     * - premium formats
     */
    private val MAIN_CLIENT: YouTubeClient = YouTubeClient.MAIN_CLIENT

    /**
     * Clients used for fallback streams in case the streams of the main client do not work.
     */
    private val STREAM_FALLBACK_CLIENTS: List<YouTubeClient> = listOf(
        TVHTML5,
        IOS,
    )

    data class PlaybackData(
        val audioConfig: PlayerResponse.PlayerConfig.AudioConfig?,
        val videoDetails: PlayerResponse.VideoDetails?,
        val format: PlayerResponse.StreamingData.Format,
        val streamUrl: String,
        val streamExpiresInSeconds: Int,
    )

    /**
     * Custom player response intended to use for playback.
     * Metadata like audioConfig and videoDetails are from [MAIN_CLIENT].
     * Format & stream can be from [MAIN_CLIENT] or [STREAM_FALLBACK_CLIENTS].
     */
    suspend fun playerResponseForPlayback(
        videoId: String,
        playlistId: String? = null,
        playedFormat: FormatEntity?,
        audioQuality: AudioQuality,
        connectivityManager: ConnectivityManager,
    ): Result<PlaybackData> = runCatching {
        /**
         * This is required for some clients to get working streams however
         * it should not be forced for the [MAIN_CLIENT] because the response of the [MAIN_CLIENT]
         * is required even if the streams won't work from this client.
         * This is why it is allowed to be null.
         */
        val signatureTimestamp = getSignatureTimestampOrNull(videoId)
        val mainPlayerResponse =
            YouTube.player(videoId, playlistId, MAIN_CLIENT, signatureTimestamp).getOrThrow()

        val audioConfig = mainPlayerResponse.playerConfig?.audioConfig
        val videoDetails = mainPlayerResponse.videoDetails

        var format: PlayerResponse.StreamingData.Format? = null
        var streamUrl: String? = null
        var streamExpiresInSeconds: Int? = null
        var streamPlayerResponse: PlayerResponse? = null

        for (clientIndex in (-1 until STREAM_FALLBACK_CLIENTS.size)) {
            streamPlayerResponse =
                when (clientIndex) {
                    -1 -> mainPlayerResponse
                    else -> {
                        if (clientIndex !in STREAM_FALLBACK_CLIENTS.indices) continue // skip if index is out of range
                        val client = STREAM_FALLBACK_CLIENTS[clientIndex]
                        if (client.loginRequired && YouTube.cookie == null) {
                            // skip client if it requires login but user is not logged in
                            continue
                        }
                        YouTube.player(videoId, playlistId, client, signatureTimestamp).getOrNull()
                    }
                }

            if (streamPlayerResponse?.statusOk() != true) continue // skip client
            format = findFormat(
                streamPlayerResponse,
                playedFormat,
                audioQuality,
                connectivityManager,
            ) ?: continue
            streamUrl = findUrlOrNull(format, videoId) ?: continue
            streamExpiresInSeconds = streamPlayerResponse.streamingData?.expiresInSeconds ?: continue

            when (clientIndex) {
                STREAM_FALLBACK_CLIENTS.size - 1 -> continue /** skip [validateStatus] for last client */
                else -> {
                    if (validateStatus(streamUrl)) break  // Found a working stream
                }
            }
        }

        if (streamPlayerResponse == null) throw Exception("Bad stream player response")
        if (!streamPlayerResponse.statusOk()) {
            throw PlaybackException(
                streamPlayerResponse.playabilityStatus.reason,
                null,
                PlaybackException.ERROR_CODE_REMOTE_ERROR
            )
        }
        if (streamExpiresInSeconds == null) throw Exception("Missing stream expire time")
        if (format == null) throw Exception("Could not find format")
        if (streamUrl == null) throw Exception("Could not find stream url")

        PlaybackData(
            audioConfig,
            videoDetails,
            format,
            streamUrl,
            streamExpiresInSeconds,
        )
    }

    /**
     * Simple player response intended to use for metadata only.
     * Stream URLs of this response might not work so don't use them.
     */
    suspend fun playerResponseForMetadata(
        videoId: String,
        playlistId: String? = null,
    ): Result<PlayerResponse> =
        YouTube.player(videoId, playlistId, client = MAIN_CLIENT)

    private fun findFormat(
        playerResponse: PlayerResponse,
        playedFormat: FormatEntity?,
        audioQuality: AudioQuality,
        connectivityManager: ConnectivityManager,
    ): PlayerResponse.StreamingData.Format? =
        if (playedFormat != null) {
            playerResponse.streamingData?.adaptiveFormats?.find { it.itag == playedFormat.itag }
        } else {
            playerResponse.streamingData?.adaptiveFormats
                ?.filter { it.isAudio }
                ?.maxByOrNull {
                    it.bitrate * when (audioQuality) {
                        AudioQuality.AUTO -> if (connectivityManager.isActiveNetworkMetered) -1 else 1
                        AudioQuality.HIGH -> 1
                        AudioQuality.LOW -> -1
                    } + (if (it.mimeType.startsWith("audio/webm")) 10240 else 0) // prefer opus stream
                }
        }

    /**
     * Checks if the stream url returns a successful status.
     * If this returns true the url is likely to work.
     * If this returns false the url might cause an error during playback.
     */
    private fun validateStatus(url: String): Boolean {
        try {
            val requestBuilder = okhttp3.Request.Builder()
                .head()
                .url(url)
            val response = httpClient.newCall(requestBuilder.build()).execute()
            return response.isSuccessful
        } catch (e: Exception) {
            reportException(e)
        }
        return false
    }

    /**
     * Wrapper around the [NewPipeUtils.getSignatureTimestamp] function which reports exceptions
     */
    private fun getSignatureTimestampOrNull(
        videoId: String
    ): Int? {
        return NewPipeUtils.getSignatureTimestamp(videoId)
            .onFailure {
                reportException(it)
            }.getOrNull()
    }

    /**
     * Wrapper around the [NewPipeUtils.getStreamUrl] function which reports exceptions
     */
    private fun findUrlOrNull(
        format: PlayerResponse.StreamingData.Format,
        videoId: String
    ): String? {
        return NewPipeUtils.getStreamUrl(format, videoId)
            .onFailure {
                reportException(it)
            }.getOrNull()
    }
}