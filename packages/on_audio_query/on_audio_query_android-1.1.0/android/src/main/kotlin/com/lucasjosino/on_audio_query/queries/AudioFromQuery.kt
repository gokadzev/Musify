package com.lucasjosino.on_audio_query.queries

import android.content.ContentResolver
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.lucasjosino.on_audio_query.PluginProvider
import com.lucasjosino.on_audio_query.controllers.PermissionController
import com.lucasjosino.on_audio_query.queries.helper.QueryHelper
import com.lucasjosino.on_audio_query.types.checkAudiosFromType
import com.lucasjosino.on_audio_query.types.sorttypes.checkSongSortType
import com.lucasjosino.on_audio_query.utils.songProjection
import io.flutter.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** OnAudiosFromQuery */
class AudioFromQuery : ViewModel() {

    companion object {
        private const val TAG = "OnAudiosFromQuery"

        private val URI: Uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
    }

    //Main parameters
    private val helper = QueryHelper()
    private var pId = 0
    private var pUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

    // None of this methods can be null.
    private lateinit var where: String
    private lateinit var whereVal: String
    private lateinit var sortType: String
    private lateinit var resolver: ContentResolver

    /**
     * Method to "query" all songs from a specific item.
     */
    fun querySongsFrom() {
        val call = PluginProvider.call()
        val result = PluginProvider.result()
        val context = PluginProvider.context()
        this.resolver = context.contentResolver

        // The type of 'item':
        //   * 0 -> Album
        //   * 1 -> Album Id
        //   * 2 -> Artist
        //   * 3 -> Artist Id
        //   * 4 -> Genre
        //   * 5 -> Genre Id
        //   * 6 -> Playlist
        val type = call.argument<Int>("type")!!

        // Sort: Type and Order.
        sortType = checkSongSortType(
            call.argument<Int>("sortType"),
            call.argument<Int>("orderType")!!,
            call.argument<Boolean>("ignoreCase")!!
        )

        Log.d(TAG, "Query config: ")
        Log.d(TAG, "\tsortType: $sortType")
        Log.d(TAG, "\ttype: $type")
        Log.d(TAG, "\turi: $URI")

        // TODO: Add a better way to handle this query
        // This will fix (for now) the problem between Android < 30 && Android > 30
        // The method used to query genres on Android >= 30 don't work properly on Android < 30 so,
        // we need separate.
        //
        // If helper == 6 (Playlist) send to 'querySongsFromPlaylistOrGenre' in any version.
        // If helper == 4 (Genre) || helper == 5 (GenreId) and Android < 30 send to
        // 'querySongsFromPlaylistOrGenre' else, follow the rest of the "normal" code.
        //
        // Why? Android 10 and below doesn't have "genre" category and we need use a "workaround".
        // 'MediaStore'(https://developer.android.com/reference/android/provider/MediaStore.Audio.AudioColumns#GENRE)
        if (type == 6 || ((type == 4 || type == 5) && Build.VERSION.SDK_INT < 30)) {
            // Works on Android 10.
            querySongsFromPlaylistOrGenre(result, call, type)
        } else {
            // Works on Android 11.
            // 'whereVal' -> Album/Artist/Genre
            // 'where' -> uri
            whereVal = call.argument<Any>("where")!!.toString()
            where = checkAudiosFromType(type)

            // Query everything in background for a better performance.
            viewModelScope.launch {
                val resultSongList = loadSongsFrom()
                result.success(resultSongList)
            }
        }
    }

    //Loading in Background
    private suspend fun loadSongsFrom(): ArrayList<MutableMap<String, Any?>> =
        withContext(Dispatchers.IO) {
            // Setup the cursor with 'uri', 'projection', 'selection'(where) and 'values'(whereVal).
            val cursor = resolver.query(URI, songProjection(), where, arrayOf(whereVal), sortType)

            val songsFromList: ArrayList<MutableMap<String, Any?>> = ArrayList()

            Log.d(TAG, "Cursor count: ${cursor?.count}")

            // For each item(song) inside this "cursor", take one and "format"
            // into a 'Map<String, dynamic>'.
            while (cursor != null && cursor.moveToNext()) {
                val tempData: MutableMap<String, Any?> = HashMap()
                for (audioMedia in cursor.columnNames) {
                    tempData[audioMedia] = helper.loadSongItem(audioMedia, cursor)
                }

                //Get a extra information from audio, e.g: extension, uri, etc..
                val tempExtraData = helper.loadSongExtraInfo(URI, tempData)
                tempData.putAll(tempExtraData)

                songsFromList.add(tempData)
            }

            // Close cursor to avoid memory leaks.
            cursor?.close()
            return@withContext songsFromList
        }

    // TODO: Remove unnecessary code.
    private fun querySongsFromPlaylistOrGenre(
        result: MethodChannel.Result,
        call: MethodCall,
        type: Int
    ) {
        val info = call.argument<Any>("where")!!

        // Check if playlist exists using the id.
        val checkedName = if (type == 4 || type == 5) {
            checkName(genreName = info.toString())
        } else {
            checkName(plName = info.toString())
        }

        if (!checkedName) pId = info.toString().toInt()

        pUri = if (type == 4 || type == 5) {
            MediaStore.Audio.Genres.Members.getContentUri("external", pId.toLong())
        } else {
            MediaStore.Audio.Playlists.Members.getContentUri("external", pId.toLong())
        }

        // Query everything in background for a better performance.
        viewModelScope.launch {
            val resultSongsFrom = loadSongsFromPlaylistOrGenre()
            result.success(resultSongsFrom)
        }
    }

    private suspend fun loadSongsFromPlaylistOrGenre(): ArrayList<MutableMap<String, Any?>> =
        withContext(Dispatchers.IO) {
            val songsFrom: ArrayList<MutableMap<String, Any?>> = ArrayList()

            val cursor = resolver.query(pUri, songProjection(), null, null, sortType)

            Log.d(TAG, "Cursor count: ${cursor?.count}")

            while (cursor != null && cursor.moveToNext()) {
                val tempData: MutableMap<String, Any?> = HashMap()

                for (media in cursor.columnNames) {
                    tempData[media] = helper.loadSongItem(media, cursor)
                }

                //Get a extra information from audio, e.g: extension, uri, etc..
                val tempExtraData = helper.loadSongExtraInfo(URI, tempData)
                tempData.putAll(tempExtraData)

                songsFrom.add(tempData)
            }

            cursor?.close()
            return@withContext songsFrom
        }

    // Return true if playlist or genre exists and false, if don't.
    private fun checkName(plName: String? = null, genreName: String? = null): Boolean {
        val uri: Uri
        val projection: Array<String>

        if (plName != null) {
            uri = MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI
            projection = arrayOf(MediaStore.Audio.Playlists.NAME, MediaStore.Audio.Playlists._ID)
        } else {
            uri = MediaStore.Audio.Genres.EXTERNAL_CONTENT_URI
            projection = arrayOf(MediaStore.Audio.Genres.NAME, MediaStore.Audio.Genres._ID)
        }

        val cursor = resolver.query(uri, projection, null, null, null)
        while (cursor != null && cursor.moveToNext()) {
            val name = cursor.getString(0)

            if (name != null && name == plName || name == genreName) {
                pId = cursor.getInt(1)
                return true
            }
        }

        cursor?.close()
        return false
    }
}
