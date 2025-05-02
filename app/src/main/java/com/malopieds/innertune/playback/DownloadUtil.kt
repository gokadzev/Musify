package com.malopieds.innertune.playback

import android.content.Context
import android.net.ConnectivityManager
import androidx.core.content.getSystemService
import androidx.core.net.toUri
import androidx.media3.database.DatabaseProvider
import androidx.media3.datasource.ResolvingDataSource
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.datasource.okhttp.OkHttpDataSource
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.offline.DownloadNotificationHelper
import com.malopieds.innertune.utils.YTPlayerUtils
import com.malopieds.innertube.YouTube
import com.malopieds.innertune.constants.AudioQuality
import com.malopieds.innertune.constants.AudioQualityKey
import com.malopieds.innertune.db.MusicDatabase
import com.malopieds.innertune.db.entities.FormatEntity
import com.malopieds.innertune.di.DownloadCache
import com.malopieds.innertune.di.PlayerCache
import com.malopieds.innertune.utils.enumPreference
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.runBlocking
import okhttp3.OkHttpClient
import java.util.concurrent.Executor
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DownloadUtil
    @Inject
    constructor(
        @ApplicationContext context: Context,
        val database: MusicDatabase,
        val databaseProvider: DatabaseProvider,
        @DownloadCache val downloadCache: SimpleCache,
        @PlayerCache val playerCache: SimpleCache,
    ) {
        private val connectivityManager = context.getSystemService<ConnectivityManager>()!!
        private val audioQuality by enumPreference(context, AudioQualityKey, AudioQuality.AUTO)
        private val songUrlCache = HashMap<String, Pair<String, Long>>()
        private val dataSourceFactory =
            ResolvingDataSource.Factory(
                CacheDataSource
                    .Factory()
                    .setCache(playerCache)
                    .setUpstreamDataSourceFactory(
                        OkHttpDataSource.Factory(
                            OkHttpClient
                                .Builder()
                                .proxy(YouTube.proxy)
                                .build(),
                        ),
                    ),
            ) { dataSpec ->
                val mediaId = dataSpec.key ?: error("No media id")
                val length = if (dataSpec.length >= 0) dataSpec.length else 1

                if (playerCache.isCached(mediaId, dataSpec.position, length)) {
                    return@Factory dataSpec
                }

                songUrlCache[mediaId]?.takeIf { it.second < System.currentTimeMillis() }?.let {
                    return@Factory dataSpec.withUri(it.first.toUri())
                }

                val playedFormat = runBlocking(Dispatchers.IO) { database.format(mediaId).first() }
                val playbackData =
                    runBlocking(Dispatchers.IO) {
                        YTPlayerUtils.playerResponseForPlayback(
                            mediaId,
                            playedFormat = playedFormat,
                            audioQuality = audioQuality,
                            connectivityManager = connectivityManager,
                        )
                    }.getOrThrow()
                val format = playbackData.format

                database.query {
                    upsert(
                        FormatEntity(
                            id = mediaId,
                            itag = format.itag,
                            mimeType = format.mimeType.split(";")[0],
                            codecs = format.mimeType.split("codecs=")[1].removeSurrounding("\""),
                            bitrate = format.bitrate,
                            sampleRate = format.audioSampleRate,
                            contentLength = format.contentLength!!,
                            loudnessDb = playbackData.audioConfig?.loudnessDb
                        ),
                    )
                }

                val streamURL = playbackData.streamUrl.let {
                    // Avoid being throttled
                    "${it}&range=0-${format.contentLength ?: 10000000}"
                }
                val expirationTime = System.currentTimeMillis() + (playbackData.streamExpiresInSeconds * 1000L)
                songUrlCache[mediaId] = streamURL to expirationTime
                dataSpec.withUri(streamURL.toUri())
            }
        val downloadNotificationHelper = DownloadNotificationHelper(context, ExoDownloadService.CHANNEL_ID)
        val downloadManager: DownloadManager =
            DownloadManager(context, databaseProvider, downloadCache, dataSourceFactory, Executor(Runnable::run)).apply {
                maxParallelDownloads = 3
                addListener(
                    ExoDownloadService.TerminalStateNotificationHelper(
                        context = context,
                        notificationHelper = downloadNotificationHelper,
                        nextNotificationId = ExoDownloadService.NOTIFICATION_ID + 1,
                    ),
                )
            }
        val downloads = MutableStateFlow<Map<String, Download>>(emptyMap())

        fun getDownload(songId: String): Flow<Download?> = downloads.map { it[songId] }

        init {
            val result = mutableMapOf<String, Download>()
            val cursor = downloadManager.downloadIndex.getDownloads()
            while (cursor.moveToNext()) {
                result[cursor.download.request.id] = cursor.download
            }
            downloads.value = result
            downloadManager.addListener(
                object : DownloadManager.Listener {
                    override fun onDownloadChanged(
                        downloadManager: DownloadManager,
                        download: Download,
                        finalException: Exception?,
                    ) {
                        downloads.update { map ->
                            map.toMutableMap().apply {
                                set(download.request.id, download)
                            }
                        }
                    }
                },
            )
        }
    }
