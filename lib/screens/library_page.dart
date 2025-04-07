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
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/playlist_download_service.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/playlist_bar.dart';
import 'package:musify/widgets/section_header.dart';
import 'package:musify/widgets/section_title.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.library)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: commonSingleChildScrollViewPadding,
              child: Column(
                children: <Widget>[
                  _buildUserPlaylistsSection(primaryColor),
                  if (!offlineMode.value)
                    _buildUserLikedPlaylistsSection(primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPlaylistsSection(Color primaryColor) {
    final isUserPlaylistsEmpty =
        userPlaylists.value.isEmpty && userCustomPlaylists.value.isEmpty;
    return Column(
      children: [
        if (!offlineMode.value) ...[
          SectionHeader(
            title: context.l10n!.customPlaylists,
            actionButton: IconButton(
              padding: const EdgeInsets.only(right: 5),
              onPressed: _showAddPlaylistDialog,
              icon: Icon(FluentIcons.add_24_filled, color: primaryColor),
            ),
          ),
          PlaylistBar(
            context.l10n!.recentlyPlayed,
            onPressed:
                () => NavigationManager.router.go('/library/userSongs/recents'),
            cubeIcon: FluentIcons.history_24_filled,
            borderRadius: commonCustomBarRadiusFirst,
            showBuildActions: false,
          ),
          PlaylistBar(
            context.l10n!.likedSongs,
            onPressed:
                () => NavigationManager.router.go('/library/userSongs/liked'),
            cubeIcon: FluentIcons.music_note_2_24_regular,
            showBuildActions: false,
          ),
          PlaylistBar(
            context.l10n!.offlineSongs,
            onPressed:
                () => NavigationManager.router.go('/library/userSongs/offline'),
            cubeIcon: FluentIcons.cellular_off_24_filled,
            borderRadius:
                isUserPlaylistsEmpty
                    ? commonCustomBarRadiusLast
                    : BorderRadius.zero,
            showBuildActions: false,
          ),

          ValueListenableBuilder<List>(
            valueListenable: userCustomPlaylists,
            builder: (context, playlists, _) {
              if (playlists.isEmpty) {
                return const SizedBox();
              }
              return _buildPlaylistListView(context, playlists);
            },
          ),
        ],

        _buildOfflinePlaylistsSection(),

        if (!offlineMode.value)
          ValueListenableBuilder<List>(
            valueListenable: userPlaylists,
            builder: (context, playlists, _) {
              if (userPlaylists.value.isEmpty) {
                return const SizedBox();
              }
              return Column(
                children: [
                  SectionHeader(
                    title: context.l10n!.addedPlaylists,
                    actionButton: IconButton(
                      padding: const EdgeInsets.only(right: 5),
                      onPressed: _showAddPlaylistDialog,
                      icon: Icon(
                        FluentIcons.add_24_filled,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  FutureBuilder(
                    future: getUserPlaylists(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData &&
                          snapshot.data!.isNotEmpty) {
                        return _buildPlaylistListView(context, snapshot.data!);
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildUserLikedPlaylistsSection(Color primaryColor) {
    return ValueListenableBuilder(
      valueListenable: currentLikedPlaylistsLength,
      builder: (_, value, __) {
        return userLikedPlaylists.isNotEmpty
            ? Column(
              children: [
                SectionTitle(context.l10n!.likedPlaylists, primaryColor),
                _buildPlaylistListView(context, userLikedPlaylists),
              ],
            )
            : const SizedBox();
      },
    );
  }

  Widget _buildOfflinePlaylistsSection() {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: offlinePlaylistService.offlinePlaylists,
      builder: (context, offlinePlaylists, _) {
        if (offlinePlaylists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            SectionHeader(title: context.l10n!.offlinePlaylists),
            _buildPlaylistListView(context, offlinePlaylists),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistListView(BuildContext context, List playlists) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      padding: commonListViewBottmomPadding,
      itemBuilder: (BuildContext context, index) {
        final playlist = playlists[index];
        final borderRadius = getItemBorderRadius(index, playlists.length);
        return PlaylistBar(
          key: ValueKey(playlist['ytid']),
          playlist['title'],
          playlistId: playlist['ytid'],
          playlistArtwork: playlist['image'],
          isAlbum: playlist['isAlbum'],
          playlistData: playlist['source'] == 'user-created' ? playlist : null,
          onDelete:
              playlist['source'] == 'user-created' ||
                      playlist['source'] == 'user-youtube'
                  ? () => _showRemovePlaylistDialog(playlist)
                  : null,
          borderRadius: borderRadius,
        );
      },
    );
  }

  void _showAddPlaylistDialog() => showDialog(
    context: context,
    builder: (BuildContext context) {
      var id = '';
      var customPlaylistName = '';
      var isYouTubeMode = true;
      String? imageUrl;

      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final activeButtonBackground = theme.colorScheme.surfaceContainer;
          final inactiveButtonBackground = theme.colorScheme.secondaryContainer;
          final dialogBackgroundColor = theme.dialogTheme.backgroundColor;

          return AlertDialog(
            backgroundColor: dialogBackgroundColor,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isYouTubeMode = true;
                            id = '';
                            customPlaylistName = '';
                            imageUrl = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isYouTubeMode
                                  ? inactiveButtonBackground
                                  : activeButtonBackground,
                        ),
                        child: const Icon(FluentIcons.globe_add_24_filled),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isYouTubeMode = false;
                            id = '';
                            customPlaylistName = '';
                            imageUrl = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isYouTubeMode
                                  ? activeButtonBackground
                                  : inactiveButtonBackground,
                        ),
                        child: const Icon(FluentIcons.person_add_24_filled),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (isYouTubeMode)
                    TextField(
                      decoration: InputDecoration(
                        labelText: context.l10n!.youtubePlaylistLinkOrId,
                      ),
                      onChanged: (value) {
                        id = value;
                      },
                    )
                  else ...[
                    TextField(
                      decoration: InputDecoration(
                        labelText: context.l10n!.customPlaylistName,
                      ),
                      onChanged: (value) {
                        customPlaylistName = value;
                      },
                    ),
                    const SizedBox(height: 7),
                    TextField(
                      decoration: InputDecoration(
                        labelText: context.l10n!.customPlaylistImgUrl,
                      ),
                      onChanged: (value) {
                        imageUrl = value;
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(context.l10n!.add.toUpperCase()),
                onPressed: () async {
                  if (isYouTubeMode && id.isNotEmpty) {
                    showToast(context, await addUserPlaylist(id, context));
                  } else if (!isYouTubeMode && customPlaylistName.isNotEmpty) {
                    showToast(
                      context,
                      createCustomPlaylist(
                        customPlaylistName,
                        imageUrl,
                        context,
                      ),
                    );
                  } else {
                    showToast(
                      context,
                      '${context.l10n!.provideIdOrNameError}.',
                    );
                  }

                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    },
  );

  void _showRemovePlaylistDialog(Map playlist) => showDialog(
    context: context,
    builder: (BuildContext context) {
      return ConfirmationDialog(
        confirmationMessage: context.l10n!.removePlaylistQuestion,
        submitMessage: context.l10n!.remove,
        onCancel: () {
          Navigator.of(context).pop();
        },
        onSubmit: () {
          Navigator.of(context).pop();

          if (playlist['ytid'] == null &&
              playlist['source'] == 'user-created') {
            removeUserCustomPlaylist(playlist);
          } else {
            removeUserPlaylist(playlist['ytid']);
          }
        },
      );
    },
  );
}
