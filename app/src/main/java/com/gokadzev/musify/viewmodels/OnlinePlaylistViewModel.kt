package com.gokadzev.musify.viewmodels

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gokadzev.innertube.YouTube
import com.gokadzev.innertube.models.PlaylistItem
import com.gokadzev.innertube.models.SongItem
import com.gokadzev.musify.utils.reportException
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OnlinePlaylistViewModel
    @Inject
    constructor(
        savedStateHandle: SavedStateHandle,
    ) : ViewModel() {
        private val playlistId = savedStateHandle.get<String>("playlistId")!!

        val playlist = MutableStateFlow<PlaylistItem?>(null)
        val playlistSongs = MutableStateFlow<List<SongItem>>(emptyList())

        init {
            viewModelScope.launch(Dispatchers.IO) {
                YouTube
                    .playlist(playlistId)
                    .onSuccess { playlistPage ->
                        playlist.value = playlistPage.playlist
                        playlistSongs.value = playlistPage.songs
                    }.onFailure {
                        reportException(it)
                    }
            }
        }
    }
