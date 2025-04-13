/*
 *     Copyright (C) 2025 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/custom_bar.dart';
import 'package:musify/widgets/custom_search_bar.dart';
import 'package:musify/widgets/playlist_bar.dart';
import 'package:musify/widgets/section_title.dart';
import 'package:musify/widgets/song_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

List searchHistory = Hive.box('user').get('searchHistory', defaultValue: []);

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchBar = TextEditingController();
  final FocusNode _inputNode = FocusNode();
  final ValueNotifier<bool> _fetchingSongs = ValueNotifier(false);
  int maxSongsInList = 15;
  List _songsSearchResult = [];
  List _albumsSearchResult = [];
  List _playlistsSearchResult = [];
  List _suggestionsList = [];

  @override
  void dispose() {
    _searchBar.dispose();
    _inputNode.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final query = _searchBar.text;

    if (query.isEmpty) {
      _songsSearchResult = [];
      _albumsSearchResult = [];
      _playlistsSearchResult = [];
      _suggestionsList = [];
      setState(() {});
      return;
    }

    if (!_fetchingSongs.value) {
      _fetchingSongs.value = true;
    }

    if (!searchHistory.contains(query)) {
      searchHistory.insert(0, query);
      await addOrUpdateData('user', 'searchHistory', searchHistory);
    }

    try {
      _songsSearchResult = await fetchSongsList(query);
      _albumsSearchResult = await getPlaylists(query: query, type: 'album');
      _playlistsSearchResult = await getPlaylists(
        query: query,
        type: 'playlist',
      );
    } catch (e, stackTrace) {
      logger.log('Error while searching online songs', e, stackTrace);
    }

    if (_fetchingSongs.value) {
      _fetchingSongs.value = false;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.search)),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: <Widget>[
            CustomSearchBar(
              loadingProgressNotifier: _fetchingSongs,
              controller: _searchBar,
              focusNode: _inputNode,
              labelText: '${context.l10n!.search}...',
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  _suggestionsList = await getSearchSuggestions(value);
                } else {
                  _suggestionsList = [];
                }
                setState(() {});
              },
              onSubmitted: (String value) {
                search();
                _suggestionsList = [];
                _inputNode.unfocus();
              },
            ),
            if (_songsSearchResult.isEmpty && _albumsSearchResult.isEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    _suggestionsList.isEmpty
                        ? searchHistory.length
                        : _suggestionsList.length,
                itemBuilder: (BuildContext context, int index) {
                  final suggestionsNotAvailable = _suggestionsList.isEmpty;
                  final query =
                      suggestionsNotAvailable
                          ? searchHistory[index]
                          : _suggestionsList[index];

                  final borderRadius = getItemBorderRadius(
                    index,
                    _suggestionsList.isEmpty
                        ? searchHistory.length
                        : _suggestionsList.length,
                  );

                  return CustomBar(
                    query,
                    FluentIcons.search_24_regular,
                    borderRadius: borderRadius,
                    onTap: () async {
                      _searchBar.text = query;
                      await search();
                      _inputNode.unfocus();
                    },
                    onLongPress: () async {
                      final confirm =
                          await _showConfirmationDialog(context) ?? false;

                      if (confirm) {
                        setState(() {
                          searchHistory.remove(query);
                        });

                        await addOrUpdateData(
                          'user',
                          'searchHistory',
                          searchHistory,
                        );
                      }
                    },
                  );
                },
              )
            else
              Column(
                children: [
                  SectionTitle(context.l10n!.songs, primaryColor),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        _songsSearchResult.length > maxSongsInList
                            ? maxSongsInList
                            : _songsSearchResult.length,
                    itemBuilder: (BuildContext context, int index) {
                      final borderRadius = getItemBorderRadius(
                        index,
                        _songsSearchResult.length > maxSongsInList
                            ? maxSongsInList
                            : _songsSearchResult.length,
                      );

                      return SongBar(
                        _songsSearchResult[index],
                        true,
                        showMusicDuration: true,
                        borderRadius: borderRadius,
                      );
                    },
                  ),
                  if (_albumsSearchResult.isNotEmpty)
                    SectionTitle(context.l10n!.albums, primaryColor),
                  if (_albumsSearchResult.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          _albumsSearchResult.length > maxSongsInList
                              ? maxSongsInList
                              : _albumsSearchResult.length,
                      itemBuilder: (BuildContext context, int index) {
                        final playlist = _albumsSearchResult[index];

                        final borderRadius = getItemBorderRadius(
                          index,
                          _albumsSearchResult.length > maxSongsInList
                              ? maxSongsInList
                              : _albumsSearchResult.length,
                        );

                        return PlaylistBar(
                          key: ValueKey(playlist['ytid']),
                          playlist['title'],
                          playlistId: playlist['ytid'],
                          playlistArtwork: playlist['image'],
                          cubeIcon: FluentIcons.cd_16_filled,
                          isAlbum: true,
                          borderRadius: borderRadius,
                        );
                      },
                    ),
                  if (_playlistsSearchResult.isNotEmpty)
                    SectionTitle(context.l10n!.playlists, primaryColor),
                  if (_playlistsSearchResult.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: commonListViewBottmomPadding,
                      itemCount:
                          _playlistsSearchResult.length > maxSongsInList
                              ? maxSongsInList
                              : _playlistsSearchResult.length,
                      itemBuilder: (BuildContext context, int index) {
                        final playlist = _playlistsSearchResult[index];
                        return PlaylistBar(
                          key: ValueKey(playlist['ytid']),
                          playlist['title'],
                          playlistId: playlist['ytid'],
                          playlistArtwork: playlist['image'],
                          cubeIcon: FluentIcons.apps_list_24_filled,
                        );
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          confirmationMessage: context.l10n!.removeSearchQueryQuestion,
          submitMessage: context.l10n!.confirm,
          onCancel: () {
            Navigator.of(context).pop(false);
          },
          onSubmit: () {
            Navigator.of(context).pop(true);
          },
        );
      },
    );
  }
}
