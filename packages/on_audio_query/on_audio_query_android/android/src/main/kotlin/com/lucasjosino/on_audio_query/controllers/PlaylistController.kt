@file:Suppress("DEPRECATION")

package com.lucasjosino.on_audio_query.controllers

import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** PlaylistController */
class PlaylistController {

    //Main parameters
    private val uri = MediaStore.Audio.Playlists.EXTERNAL_CONTENT_URI
    private val contentValues = ContentValues()
    private val channelError = "on_audio_error"
    private lateinit var resolver: ContentResolver

    //Query projection
    private val columns = arrayOf(
        "count(*)"
    )

    //
    fun createPlaylist(context: Context, result: MethodChannel.Result, call: MethodCall) {
        this.resolver = context.contentResolver

        // Get the playlist name
        val playlistName = call.argument<String>("playlistName")!!

        // Define the default values.
        contentValues.put(MediaStore.Audio.Playlists.NAME, playlistName)
        contentValues.put(MediaStore.Audio.Playlists.DATE_ADDED, System.currentTimeMillis())

        // Add to [MediaStore].
        resolver.insert(uri, contentValues)
        
        // Get the playlist id.
        val id: Int? = checkPlaylist(name = playlistName)

        // Return to Dart/Flutter
        result.success(id)
    }

    //
    fun removePlaylist(context: Context, result: MethodChannel.Result, call: MethodCall) {
        this.resolver = context.contentResolver
        val playlistId = call.argument<Int>("playlistId")!!

        //Check if Playlist exists based in Id
        if (checkPlaylist(playlistId) == -1) result.success(false)

        //
        val delUri = ContentUris.withAppendedId(uri, playlistId.toLong())
        resolver.delete(delUri, null, null)
        result.success(true)
    }

    //TODO Add option to use a list
    //TODO Fix error on Android 10
    fun addToPlaylist(context: Context, result: MethodChannel.Result, call: MethodCall) {
        this.resolver = context.contentResolver
        val playlistId = call.argument<Int>("playlistId")!!
        val audioId = call.argument<Int>("audioId")!!


        //Check if Playlist exists based in Id
        if (checkPlaylist(playlistId) == -1) result.success(false)

        //
        val uri = MediaStore.Audio.Playlists.Members.getContentUri(
            "external",
            playlistId.toLong()
        )
        //If Android is Q/10 or above "count(*)" don't count, so, we use other method.
        val columnsBasedOnVersion = if (Build.VERSION.SDK_INT < 29) columns else null
        val cursor = resolver.query(uri, columnsBasedOnVersion, null, null, null)
        var count = -1
        while (cursor != null && cursor.moveToNext()) {
            count += if (Build.VERSION.SDK_INT < 29) cursor.count else cursor.getInt(0)
        }
        cursor?.close()
        //
        try {
            contentValues.put(MediaStore.Audio.Playlists.Members.PLAY_ORDER, count + 1)
            contentValues.put(MediaStore.Audio.Playlists.Members.AUDIO_ID, audioId.toLong())
            resolver.insert(uri, contentValues)
            result.success(true)
        } catch (e: Exception) {
            Log.i(channelError, e.toString())
        }
    }

    //TODO Add option to use a list
    fun removeFromPlaylist(context: Context, result: MethodChannel.Result, call: MethodCall) {
        this.resolver = context.contentResolver
        val playlistId = call.argument<Int>("playlistId")!!
        val audioId = call.argument<Int>("audioId")!!

        //Check if Playlist exists based on Id
        if (checkPlaylist(playlistId) == -1) result.success(false)
        
        //
        try {
            val uri = MediaStore.Audio.Playlists.Members.getContentUri(
                "external",
                playlistId.toLong()
            )
            val where = MediaStore.Audio.Playlists.Members._ID + "=?"
            resolver.delete(uri, where, arrayOf(audioId.toString()))
            result.success(true)
        } catch (e: Exception) {
            Log.i("on_audio_error: ", e.toString())
            result.success(false)
        }
    }

    //TODO("Need tests")
    fun moveItemTo(context: Context, result: MethodChannel.Result, call: MethodCall) {
        this.resolver = context.contentResolver
        val playlistId = call.argument<Int>("playlistId")!!
        val from = call.argument<Int>("from")!!
        val to = call.argument<Int>("to")!!

        //Check if Playlist exists based in Id
        if (checkPlaylist(playlistId) == -1) result.success(false)
        
        //
        MediaStore.Audio.Playlists.Members.moveItem(resolver, playlistId.toLong(), from, to)
        result.success(true)
    }

    //
    fun renamePlaylist(context: Context, result: MethodChannel.Result, call: MethodCall) {
        this.resolver = context.contentResolver
        val playlistId = call.argument<Int>("playlistId")!!
        val newPlaylistName = call.argument<String>("newPlName")!!

        //Check if Playlist exists based in Id
        if (checkPlaylist(playlistId) == -1) result.success(false)
        
        //
        contentValues.put(MediaStore.Audio.Playlists.NAME, newPlaylistName)
        contentValues.put(MediaStore.Audio.Playlists.DATE_MODIFIED, System.currentTimeMillis())
        resolver.update(uri, contentValues, "_id=${playlistId.toLong()}", null)
        result.success(true)
    }

    //Return true if playlist already exist, false if don't exist
    private fun checkPlaylist(id: Int? = null, name: String? = null): Int? {
        val cursor = resolver.query(
            uri,
            arrayOf(MediaStore.Audio.Playlists.NAME, MediaStore.Audio.Playlists._ID),
            null,
            null,
            null
        )
        while (cursor != null && cursor.moveToNext()) {
            val playListName = cursor.getString(0) // Name
            val playListId = cursor.getInt(1) // Id
            if (playListName == name || playListId == id) return playListId
        }
        cursor?.close()
        return null
    }
}

//Extras:

//I/PlaylistCursor[All]: [
//  title_key
// instance_id
// playlist_id
// duration
// is_ringtone
// album_artist
// orientation
// artist
// height
// is_drm
// bucket_display_name
// is_audiobook
// owner_package_name
// volume_name
// title_resource_uri
// date_modified
// date_expires
// composer
// _display_name
// datetaken
// mime_type
// is_notification
// _id
// year
// _data
// _hash
// _size
// album
// is_alarm
// title
// track
// width
// is_music
// album_key
// is_trashed
// group_id
// document_id
// artist_id
// artist_key
// is_pending
// date_added
// audio_id
// is_podcast
// album_id
// primary_directory
// secondary_directory
// original_document_id
// bucket_id
// play_order
// bookmark
// relative_path
// ]