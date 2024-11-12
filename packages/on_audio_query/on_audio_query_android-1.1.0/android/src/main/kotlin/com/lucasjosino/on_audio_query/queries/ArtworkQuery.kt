package com.lucasjosino.on_audio_query.queries

import android.content.ContentResolver
import android.content.ContentUris
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.util.Size
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.lucasjosino.on_audio_query.PluginProvider
import com.lucasjosino.on_audio_query.queries.helper.QueryHelper
import com.lucasjosino.on_audio_query.types.checkArtworkFormat
import com.lucasjosino.on_audio_query.types.checkArtworkType
import io.flutter.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.FileInputStream

class ArtworkQuery : ViewModel() {

    companion object {
        private const val TAG = "OnArtworksQuery"
    }

    private val helper = QueryHelper()
    private var type: Int = -1
    private var id: Number = 0
    private var quality: Int = 100
    private var size: Int = 200
    private var showDetailedLog: Boolean = false

    private lateinit var uri: Uri
    private lateinit var resolver: ContentResolver
    private lateinit var format: Bitmap.CompressFormat

    /**
     * Method to "query" artwork.
     */
    fun queryArtwork() {
        val call = PluginProvider.call()
        val result = PluginProvider.result()
        val context = PluginProvider.context()
        this.resolver = context.contentResolver
        this.showDetailedLog = PluginProvider.showDetailedLog

        id = call.argument<Number>("id")!!

        // If the 'size' is null, will be '200'.
        size = call.argument<Int>("size")!!

        // The 'quality' value cannot be greater than 100 so, we check and if is, set to '50'.
        quality = call.argument<Int>("quality")!!
        if (quality > 100) quality = 50

        // Check format:
        //   * 0 -> JPEG
        //   * 1 -> PNG
        format = checkArtworkFormat(call.argument<Int>("format")!!)

        // Check uri:
        //   * 0 -> Song.
        //   * 1 -> Album.
        //   * 2 -> Playlist.
        //   * 3 -> Artist.
        //   * 4 -> Genre.
        uri = checkArtworkType(call.argument<Int>("type")!!)

        // This query is 'universal' will work for multiple types (audio, album, artist, etc...).
        type = call.argument<Int>("type")!!

        Log.d(TAG, "Query config: ")
        Log.d(TAG, "\tid: $id")
        Log.d(TAG, "\tquality: $quality")
        Log.d(TAG, "\tformat: $format")
        Log.d(TAG, "\turi: $uri")
        Log.d(TAG, "\ttype: $type")

        // Query everything in background for a better performance.
        viewModelScope.launch {
            var resultArtList = loadArt()

            // Sometimes android will extract a 'wrong' or 'empty' artwork. Just set as null.
            if (resultArtList != null && resultArtList.isEmpty()) {
                Log.i(TAG, "Artwork for '$id' is empty. Returning null")
                resultArtList = null
            }

            result.success(resultArtList)
        }
    }

    //Loading in Background
    private suspend fun loadArt(): ByteArray? = withContext(Dispatchers.IO) {
        var artData: ByteArray? = null

        // If 'Android' >= 29/Q:
        //   * Limited access to files/folders. Use 'loadThumbnail'.
        // If 'Android' < 29/Q:
        //   * Use the 'embeddedPicture' from 'MediaMetadataRetriever' to get the image.
        if (Build.VERSION.SDK_INT >= 29) {
            try {
                // If 'type' is 2, 3 or 4, Get the first item from playlist or artist.
                // Use the first artist song to 'simulate' the artwork.
                //
                // Type:
                //   * 2 -> Playlist.
                //   * 3 -> Artist.
                //   * 4 -> Genre.
                //
                // OBS: The 'id' is defined as 'Number'. Convert to 'Long'
                val query = if (type == 2 || type == 3 || type == 4) {
                    val item = helper.loadFirstItem(type, id, resolver) ?: return@withContext null
                    ContentUris.withAppendedId(uri, item.toLong())
                } else {
                    ContentUris.withAppendedId(uri, id.toLong())
                }

                val bitmap = resolver.loadThumbnail(query, Size(size, size), null)
                artData = convertOrResize(bitmap = bitmap)!!
            } catch (e: Exception) {
                // This may produce a lot of logging on console so, will required a explicit request
                // to show the errors.
                if (showDetailedLog) Log.w(TAG, "($id) Message: $e")
            }
        } else {
            // If 'uri == Audio':
            //   * Load the first 'item' from cursor using the 'id' as filter.
            // else:
            //   * Load the first 'item' from 'album' using the 'id' as filter.
            //
            // If 'item' return null, no song/album has found, return null.
            val item = helper.loadFirstItem(type, id, resolver) ?: return@withContext null

            try {
                val file = FileInputStream(item)
                val metadata = MediaMetadataRetriever()

                metadata.setDataSource(file.fd)
                val image = metadata.embeddedPicture

                // Convert image. If null, return
                artData = convertOrResize(byteArray = image) ?: return@withContext null

                // 'close' can only be called using 'Android' >= 29/Q.
                if (Build.VERSION.SDK_INT >= 29) metadata.close()
            } catch (e: Exception) {
                // This may produce a lot of logging on console so, will required a explicit request
                // to show the errors.
                if (showDetailedLog) Log.w(TAG, "($id) Message: $e")
            }
        }

        return@withContext artData
    }

    //
    private fun convertOrResize(bitmap: Bitmap? = null, byteArray: ByteArray? = null): ByteArray? {
        val convertedBytes: ByteArray?
        val byteArrayBase = ByteArrayOutputStream()

        try {
            // If 'bitmap' isn't null:
            //   * The image(bitmap) is from first method. (Android >= 29/Q).
            // else:
            //   * The image(bytearray) is from second method. (Android < 29/Q).
            if (bitmap != null) {
                bitmap.compress(format, quality, byteArrayBase)
            } else {
                val convertedBitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray!!.size)
                convertedBitmap.compress(format, quality, byteArrayBase)
            }
        } catch (e: Exception) {
            // This may produce a lot of logging on console so, will required a explicit request
            // to show the errors.
            if (showDetailedLog) Log.w(TAG, "($id) Message: $e")
        }

        convertedBytes = byteArrayBase.toByteArray()
        byteArrayBase.close()
        return convertedBytes
    }
}