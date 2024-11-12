package com.lucasjosino.on_audio_query.queries

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.net.Uri
import android.provider.MediaStore
import com.lucasjosino.on_audio_query.PluginProvider
import io.flutter.Log
import java.io.File

/** OnAllPathQuery */
class AllPathQuery {

    companion object {
        private const val TAG = "OnAllPathQuery"

        private val URI: Uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
    }

    private lateinit var resolver: ContentResolver

    /**
     * Method to "query" all paths.
     */
    fun queryAllPath() {
        val result = PluginProvider.result()
        val context = PluginProvider.context()
        this.resolver = context.contentResolver

        val resultAllPath = loadAllPath()
        result.success(resultAllPath)
    }

    // Ignore the '_data' deprecation because this plugin support older versions.
    @SuppressLint("Range")
    private fun loadAllPath(): ArrayList<String> {
        val cursor = resolver.query(URI, null, null, null, null)

        val songPathList: ArrayList<String> = ArrayList()

        Log.d(TAG, "Cursor count: ${cursor?.count}")

        // For each item(path) inside this "cursor", take one and add to the list.
        while (cursor != null && cursor.moveToNext()) {
            val content = cursor.getString(cursor.getColumnIndex(MediaStore.Audio.Media.DATA))

            val path = File(content).parent

            // Check if path is null or if already exist inside list.
            if (path != null && !songPathList.contains(path)) {
                songPathList.add(path)
            }
        }

        // Close cursor to avoid memory leaks.
        cursor?.close()
        return songPathList
    }
}