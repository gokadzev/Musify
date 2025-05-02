package com.gokadzev.musify.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gokadzev.innertube.YouTube
import com.gokadzev.innertube.models.PlaylistItem
import com.gokadzev.musify.utils.reportException
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AccountViewModel
    @Inject
    constructor() : ViewModel() {
        val playlists = MutableStateFlow<List<PlaylistItem>?>(null)

        init {
            viewModelScope.launch {
                YouTube
                    .likedPlaylists()
                    .onSuccess {
                        playlists.value = it
                    }.onFailure {
                        reportException(it)
                    }
            }
        }
    }
