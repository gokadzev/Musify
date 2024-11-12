package com.lucasjosino.on_audio_query.queries

import android.content.ContentResolver
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.lucasjosino.on_audio_query.PluginProvider
import com.lucasjosino.on_audio_query.queries.helper.QueryHelper
import com.lucasjosino.on_audio_query.types.checkAudiosUriType
import com.lucasjosino.on_audio_query.types.sorttypes.checkSongSortType
import com.lucasjosino.on_audio_query.utils.songProjection
import io.flutter.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** OnAudiosQuery */
class AudioQuery : ViewModel() {

    companion object {
        private const val TAG = "OnAudiosQuery"
    }

    // Main parameters
    private val helper = QueryHelper()
    private var selection: String? = null

    private lateinit var uri: Uri
    private lateinit var sortType: String
    private lateinit var resolver: ContentResolver

    /**
     * Method to "query" all songs.
     */
    fun querySongs() {
        val call = PluginProvider.call()
        val result = PluginProvider.result()
        val context = PluginProvider.context()
        this.resolver = context.contentResolver

        // Sort: Type and Order.
        sortType = checkSongSortType(
            call.argument<Int>("sortType"),
            call.argument<Int>("orderType")!!,
            call.argument<Boolean>("ignoreCase")!!
        )

        // Check uri:
        //   * 0 -> External.
        //   * 1 -> Internal.
        uri = checkAudiosUriType(call.argument<Int>("uri")!!)

        // Here we provide a custom 'path'.
        if (call.argument<String>("path") != null) {
            val projection = songProjection()
            selection = projection[0] + " like " + "'%" + call.argument<String>("path") + "/%'"
        }

        Log.d(TAG, "Query config: ")
        Log.d(TAG, "\tsortType: $sortType")
        Log.d(TAG, "\tselection: $selection")
        Log.d(TAG, "\turi: $uri")

        // Query everything in background for a better performance.
        viewModelScope.launch {
            val queryResult = loadSongs()
            result.success(queryResult)
        }
    }

    //Loading in Background
    private suspend fun loadSongs(): ArrayList<MutableMap<String, Any?>> =
        withContext(Dispatchers.IO) {
            // Setup the cursor with 'uri', 'projection' and 'sortType'.
            val cursor = resolver.query(uri, songProjection(), selection, null, sortType)

            val songList: ArrayList<MutableMap<String, Any?>> = ArrayList()

            Log.d(TAG, "Cursor count: ${cursor?.count}")

            // For each item(song) inside this "cursor", take one and "format"
            // into a 'Map<String, dynamic>'.
            while (cursor != null && cursor.moveToNext()) {
                val tempData: MutableMap<String, Any?> = HashMap()

                for (audioMedia in cursor.columnNames) {
                    tempData[audioMedia] = helper.loadSongItem(audioMedia, cursor)
                }

                //Get a extra information from audio, e.g: extension, uri, etc..
                val tempExtraData = helper.loadSongExtraInfo(uri, tempData)
                tempData.putAll(tempExtraData)

                songList.add(tempData)
            }

            // Close cursor to avoid memory leaks.
            cursor?.close()
            return@withContext songList
        }
}
