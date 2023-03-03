package com.lucasjosino.on_audio_query.methods.queries

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.lucasjosino.on_audio_query.controllers.PermissionController
import com.lucasjosino.on_audio_query.methods.helper.QueryHelper
import com.lucasjosino.on_audio_query.types.checkAudioType
import com.lucasjosino.on_audio_query.types.checkAudiosUriType
import com.lucasjosino.on_audio_query.types.sorttypes.checkAudioSortType
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** AudiosQuery */
class AudiosQuery : ViewModel() {

    // Main parameters
    private val helper = QueryHelper()
    private var selection: String = ""

    // None of this methods can be null.
    private lateinit var uri: Uri
    private lateinit var resolver: ContentResolver
    private lateinit var sortType: String

    // Audios projection
    // Ignore the [Data] deprecation because this plugin support older versions.
    @Suppress("DEPRECATION")
    val audioProjection: Array<String>
        @SuppressLint("InlinedApi")
        get() : Array<String> {
            val tmpProjection = arrayListOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.DISPLAY_NAME,
                MediaStore.Audio.Media.SIZE,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.ALBUM_ARTIST,
                MediaStore.Audio.Media.ALBUM_ID,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ARTIST_ID,
                MediaStore.Audio.Media.BOOKMARK,
                MediaStore.Audio.Media.COMPOSER,
                MediaStore.Audio.Media.DATE_ADDED,
                MediaStore.Audio.Media.DATE_MODIFIED,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.TRACK,
                MediaStore.Audio.Media.YEAR,
                MediaStore.Audio.Media.IS_ALARM,
                MediaStore.Audio.Media.IS_MUSIC,
                MediaStore.Audio.Media.IS_NOTIFICATION,
                MediaStore.Audio.Media.IS_PODCAST,
                MediaStore.Audio.Media.IS_RINGTONE,
            )

            // Only Api >= 29
            if (Build.VERSION.SDK_INT >= 29) {
                tmpProjection.add(MediaStore.Audio.Media.IS_AUDIOBOOK)
            }

            // Only Api >= 30
            if (Build.VERSION.SDK_INT >= 30) {
                tmpProjection.add(MediaStore.Audio.Media.GENRE)
                tmpProjection.add(MediaStore.Audio.Media.GENRE_ID)
            }

            return tmpProjection.toTypedArray()
        }

    @Suppress("UNCHECKED_CAST")
    fun init(
        context: Context,
        // Call from 'MethodChannel' (method).
        result: MethodChannel.Result? = null,
        call: MethodCall? = null,
        // Call from 'EventChannel' (observer).
        sink: EventChannel.EventSink? = null,
        args: Map<*, *>? = null
    ) {
        // Define the [resolver]. This method is used to call the [query].
        resolver = context.contentResolver

        // Define the [args]. Will be delivered from:
        // [result](From MethodChannel) or [sink](From EventChannel)
        val pArgs: Map<String, Any?> = (args ?: call?.arguments) as Map<String, Any?>

        // Define all 'basic' filters.
        val pSortType: Int? = pArgs["sortType"] as Int?
        val pOrderType: Int = pArgs["orderType"] as Int
        val pIgnoreCase: Boolean = pArgs["ignoreCase"] as Boolean
        val pUri: Int = pArgs["uri"] as Int
        val pLimit: Int? = pArgs["limit"] as Int?

        // Define the [toQuery], [toRemove] and [type] filters.
        val toQuery: Map<Int, ArrayList<String>> = pArgs["toQuery"] as Map<Int, ArrayList<String>>
        val toRemove: Map<Int, ArrayList<String>> = pArgs["toRemove"] as Map<Int, ArrayList<String>>
        val type: Map<Int, Int> = pArgs["type"] as Map<Int, Int>

        // Sort: Type and Order.
        sortType = checkAudioSortType(pSortType, pOrderType, pIgnoreCase)

        // Add a 'query' limit(if not null).
        if (pLimit != null) sortType += " LIMIT $pLimit"

        // Check uri:
        //   * [0]: External.
        //   * [1]: Internal.
        uri = checkAudiosUriType(pUri)

        // TODO: Add a generic toQuery and toRemove builder. This will remove a lot of unnecessary code.
        // For every 'row' from 'toQuery', *keep* the media that contains the 'filter'.
        for ((id: Int, values: ArrayList<String>) in toQuery) {
            for (value in values) {
                // The comparison type: contains
                selection += audioProjection[id] + " LIKE '%" + value + "%' " + "AND "
            }
        }

        // For every 'row' from 'toRemove', *remove* the media that contains the 'filter'.
        for ((id: Int, values: ArrayList<String>) in toRemove) {
            for (value in values) {
                // The comparison type: contains
                selection += audioProjection[id] + " NOT LIKE '%" + value + "%' " + "AND "
            }
        }

        // Add/Remove audio type. E.g: is Music, Notification, Alarm, etc..
        for (audioType in type) {
            selection += checkAudioType(audioType.key) + "=" + "${audioType.value} " + "AND "
        }

        // Remove the 'AND ' keyword from selection.
        selection = selection.removeSuffix("AND ")

        // Request permission status from the 'main' method.
        val hasPermission: Boolean = PermissionController().permissionStatus(context)

        // We cannot 'query' without permission so, throw a PlatformException.
        // Only one 'channel' will be 'functional'. If is null, ignore, if not, send the error.
        if (!hasPermission) {
            // Method from 'EventChannel' (observer)
            sink?.error(
                "403",
                "The app doesn't have permission to read files.",
                "Call the [permissionsRequest] method or install a external plugin to handle the app permission."
            )
            // Method from 'MethodChannel' (method)
            result?.error(
                "403",
                "The app doesn't have permission to read files.",
                "Call the [permissionsRequest] method or install a external plugin to handle the app permission."
            )

            // 'Exit' the function
            return
        }

        // Query everything in background for a better performance.
        viewModelScope.launch {
            // Start 'querying'.
            val resultAudioList: ArrayList<MutableMap<String, Any?>> = loadAudios()

            // After loading the information, send the 'result'.
            sink?.success(resultAudioList)
            result?.success(resultAudioList)
        }
    }

    //Loading in Background
    private suspend fun loadAudios(): ArrayList<MutableMap<String, Any?>> =
        withContext(Dispatchers.IO) {
            // Setup the cursor with [uri], [projection] and [sortType].
            val cursor = resolver.query(uri, audioProjection, selection, null, sortType)

            // Empty list.
            val audioList: ArrayList<MutableMap<String, Any?>> = ArrayList()

            // For each item(audio) inside this "cursor", take one and "format"
            // into a [Map<String, dynamic>].
            while (cursor != null && cursor.moveToNext()) {
                val tempData: MutableMap<String, Any?> = HashMap()
                for (audioMedia in cursor.columnNames) {
                    tempData[audioMedia] = helper.loadAudioItem(audioMedia, cursor)
                }

                //Get a extra information from audio, e.g: extension, uri, etc..
                val tempExtraData = helper.loadAudioExtraInfo(uri, tempData)
                tempData.putAll(tempExtraData)

                audioList.add(tempData)
            }

            // Close cursor to avoid memory leaks.
            cursor?.close()

            // After finish the "query", go back to the "main" thread(You can only call flutter
            // inside the main thread).
            return@withContext audioList
        }
}

//Extras:

// * Query only audio > 60000 ms [1 minute]
// Obs: I don't think is a good idea, some audio "Non music" have more than 1 minute
//query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, projection, MediaStore.Audio.Media.DURATION +
// ">= 60000", null, checkAudioSortType(sortType!!))

// * Query audio with limit, used for better performance in tests
//MediaStore.Audio.Media.TITLE + " LIMIT 4"