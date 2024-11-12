package com.lucasjosino.on_audio_query.queries

import android.content.ContentResolver
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.lucasjosino.on_audio_query.PluginProvider
import com.lucasjosino.on_audio_query.controllers.PermissionController
import com.lucasjosino.on_audio_query.queries.helper.QueryHelper
import com.lucasjosino.on_audio_query.types.checkPlaylistsUriType
import com.lucasjosino.on_audio_query.types.sorttypes.checkGenreSortType
import com.lucasjosino.on_audio_query.utils.playlistProjection
import io.flutter.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** OnPlaylistQuery */
class PlaylistQuery : ViewModel() {

    companion object {
        private const val TAG = "OnPlaylistQuery"
    }

    //Main parameters
    private val helper = QueryHelper()

    private lateinit var uri: Uri
    private lateinit var resolver: ContentResolver
    private lateinit var sortType: String

    /**
     * Method to "query" all playlists.
     */
    fun queryPlaylists() {
        val call = PluginProvider.call()
        val result = PluginProvider.result()
        val context = PluginProvider.context()
        this.resolver = context.contentResolver

        // Sort: Type and Order.
        sortType = checkGenreSortType(
            call.argument<Int>("sortType"),
            call.argument<Int>("orderType")!!,
            call.argument<Boolean>("ignoreCase")!!
        )
        // Check uri:
        //   * 0 -> External.
        //   * 1 -> Internal.
        uri = checkPlaylistsUriType(call.argument<Int>("uri")!!)

        Log.d(TAG, "Query config: ")
        Log.d(TAG, "\tsortType: $sortType")
        Log.d(TAG, "\turi: $uri")

        // Query everything in background for a better performance.
        viewModelScope.launch {
            val queryResult = loadPlaylists()
            result.success(queryResult)
        }
    }

    //Loading in Background
    private suspend fun loadPlaylists(): ArrayList<MutableMap<String, Any?>> =
        withContext(Dispatchers.IO) {
            // Setup the cursor with 'uri' and 'projection'.
            val cursor = resolver.query(uri, playlistProjection, null, null, null)

            val playlistList: ArrayList<MutableMap<String, Any?>> = ArrayList()

            Log.d(TAG, "Cursor count: ${cursor?.count}")

            // For each item(playlist) inside this "cursor", take one and "format"
            // into a 'Map<String, dynamic>'.
            while (cursor != null && cursor.moveToNext()) {
                val playlistData: MutableMap<String, Any?> = HashMap()

                for (playlistMedia in cursor.columnNames) {
                    playlistData[playlistMedia] = helper.loadPlaylistItem(playlistMedia, cursor)
                }

                // Count and add the number of songs for every playlist.
                val mediaCount = helper.getMediaCount(1, playlistData["_id"].toString(), resolver)
                playlistData["num_of_songs"] = mediaCount

                playlistList.add(playlistData)
            }

            // Close cursor to avoid memory leaks.
            cursor?.close()
            return@withContext playlistList
        }
}
