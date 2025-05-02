package com.malopieds.innertune.viewmodels

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.malopieds.innertube.YouTube
import com.malopieds.innertube.pages.ArtistPage
import com.malopieds.innertune.constants.HideExplicitKey
import com.malopieds.innertune.db.MusicDatabase
import com.malopieds.innertune.utils.dataStore
import com.malopieds.innertune.utils.get
import com.malopieds.innertune.utils.reportException
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ArtistViewModel
    @Inject
    constructor(
        @ApplicationContext context: Context,
        database: MusicDatabase,
        savedStateHandle: SavedStateHandle,
    ) : ViewModel() {
        val artistId = savedStateHandle.get<String>("artistId")!!
        var artistPage by mutableStateOf<ArtistPage?>(null)
        val libraryArtist =
            database
                .artist(artistId)
                .stateIn(viewModelScope, SharingStarted.Lazily, null)
        val librarySongs =
            database
                .artistSongsPreview(artistId)
                .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

        init {
            viewModelScope.launch {
                YouTube
                    .artist(artistId)
                    .onSuccess {
                        artistPage = it.filterExplicit(context.dataStore.get(HideExplicitKey, false))
                    }.onFailure {
                        reportException(it)
                    }
            }
        }
    }
