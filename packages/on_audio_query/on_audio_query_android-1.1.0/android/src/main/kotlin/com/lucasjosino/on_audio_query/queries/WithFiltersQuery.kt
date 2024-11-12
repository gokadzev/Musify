package com.lucasjosino.on_audio_query.queries

import android.content.ContentResolver
import android.net.Uri
import android.provider.MediaStore
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.lucasjosino.on_audio_query.PluginProvider
import com.lucasjosino.on_audio_query.queries.helper.QueryHelper
import com.lucasjosino.on_audio_query.types.*
import io.flutter.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class WithFiltersQuery : ViewModel() {

    companion object {
        private const val TAG = "OnWithFiltersQuery"

        private val URI = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
    }

    //Main parameters
    private val helper = QueryHelper()
    private var projection: Array<String>? = arrayOf()

    private lateinit var resolver: ContentResolver
    private lateinit var withType: Uri
    private lateinit var argsVal: String
    private lateinit var argsKey: String

    //
    fun queryWithFilters() {
        val call = PluginProvider.call()
        val result = PluginProvider.result()
        val context = PluginProvider.context()
        this.resolver = context.contentResolver

        // Choose the type.
        //   * 0 -> Audios
        //   * 1 -> Albums
        //   * 2 -> Playlists
        //   * 3 -> Artists
        //   * 4 -> Genres
        withType = checkWithFiltersType(call.argument<Int>("withType")!!)

        // The 'args' are converted to 'String' before send to 'MethodChannel'.
        argsVal = "%" + call.argument<String>("argsVal")!! + "%"

        // A dynamic 'projection' to every type of "query".
        projection = checkProjection(withType)

        // Choose the 'arg'.
        argsKey = when (withType) {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI -> checkSongsArgs(call.argument<Int>("args")!!)
            MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI -> checkAlbumsArgs(call.argument<Int>("args")!!)
            MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI -> checkPlaylistsArgs(
                call.argument<Int>(
                    "args"
                )!!
            )
            MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI -> checkArtistsArgs(call.argument<Int>("args")!!)
            MediaStore.Audio.Genres.EXTERNAL_CONTENT_URI -> checkGenresArgs(call.argument<Int>("args")!!)
            else -> throw Exception("[argsKey] returned null. Report this issue on [on_audio_query] GitHub.")
        }

        Log.d(TAG, "Query config: ")
        Log.d(TAG, "\twithType: $withType")
        Log.d(TAG, "\targsVal: $argsVal")
        Log.d(TAG, "\targsKey: $argsKey")

        // Query everything in background for a better performance.
        viewModelScope.launch {
            val queryResult = loadWithFilters()
            result.success(queryResult)
        }
    }

    //Loading in Background
    private suspend fun loadWithFilters(): ArrayList<MutableMap<String, Any?>> =
        withContext(Dispatchers.IO) {
            // Setup the cursor with 'uri', 'projection', 'argsKey' and 'argsVal'.
            val cursor = resolver.query(withType, projection, argsKey, arrayOf(argsVal), null)

            val withFiltersList: ArrayList<MutableMap<String, Any?>> = ArrayList()

            Log.d(TAG, "Cursor count: ${cursor?.count}")

            // For each item inside this "cursor", take one and "format"
            // into a 'Map<String, dynamic>'.
            while (cursor != null && cursor.moveToNext()) {
                val tempData: MutableMap<String, Any?> = HashMap()

                for (media in cursor.columnNames) {
                    tempData[media] = helper.chooseWithFilterType(
                        withType,
                        media,
                        cursor
                    )
                }

                // If 'withType' is a song media, add the extra information.
                if (withType == MediaStore.Audio.Media.EXTERNAL_CONTENT_URI) {
                    //Get a extra information from audio, e.g: extension, uri, etc..
                    val tempExtraData = helper.loadSongExtraInfo(URI, tempData)
                    tempData.putAll(tempExtraData)
                }

                withFiltersList.add(tempData)
            }

            // Close cursor to avoid memory leaks.
            cursor?.close()
            return@withContext withFiltersList
        }
}