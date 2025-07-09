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
import 'package:musify/screens/playlist_folder_page.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/utilities/common_variables.dart';

class PlaylistBar extends StatelessWidget {
  PlaylistBar(
    this.playlistTitle, {
    super.key,
    this.playlistId,
    this.playlistArtwork,
    this.playlistData,
    this.onPressed,
    this.onDelete,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
    this.showBuildActions = true,
    this.isAlbum = false,
    this.borderRadius = BorderRadius.zero,
  }) : playlistLikeStatus = ValueNotifier<bool>(
         isPlaylistAlreadyLiked(playlistId),
       );

  final Map? playlistData;
  final String? playlistId;
  final String playlistTitle;
  final String? playlistArtwork;
  final VoidCallback? onPressed;
  final VoidCallback? onDelete;
  final IconData cubeIcon;
  final bool? isAlbum;
  final bool showBuildActions;
  final BorderRadius borderRadius;

  static const double artworkSize = 60;
  static const double iconSize = 27;

  final ValueNotifier<bool> playlistLikeStatus;

  static const likeStatusToIconMapper = {
    true: FluentIcons.heart_24_filled,
    false: FluentIcons.heart_24_regular,
  };

  // Helper to determine if this is a folder
  bool get isFolder =>
      playlistData != null && playlistData!.containsKey('playlists');

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    Map<dynamic, dynamic>? updatedPlaylist;
    return Padding(
      padding: commonBarPadding,
      child: GestureDetector(
        onTap:
            onPressed ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PlaylistPage(
                        playlistId: playlistId,
                        playlistData: updatedPlaylist ?? playlistData,
                      ),
                ),
              ).then((isPlaylistUpdated) {
                if (playlistId != null &&
                    isPlaylistUpdated != null &&
                    isPlaylistUpdated) {
                  getPlaylistInfoForWidget(
                    playlistId,
                  ).then((result) => {updatedPlaylist = result});
                }
              });
            },
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          margin: const EdgeInsets.only(bottom: 3),
          child: ListTile(
            contentPadding: commonBarContentPadding,
            leading:
                isFolder
                    ? _buildFolderIcon(primaryColor)
                    : _buildPlaylistIcon(primaryColor),
            title: Text(
              playlistTitle,
              style: commonBarTitleStyle.copyWith(color: primaryColor),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: isFolder ? _buildFolderSubtitle(context) : null,
            trailing:
                showBuildActions
                    ? _buildActionButtons(context, primaryColor)
                    : null,
            onTap: onPressed ?? _getDefaultOnPressed(context, updatedPlaylist),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistIcon(Color primaryColor) {
    if (playlistArtwork != null && playlistArtwork!.isNotEmpty) {
      // Use artwork if available
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image:
                playlistArtwork!.startsWith('http')
                    ? NetworkImage(playlistArtwork!) as ImageProvider
                    : AssetImage(playlistArtwork!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Use icon with consistent styling
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: primaryColor.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(cubeIcon, color: primaryColor, size: 24),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surface,
      icon: Icon(FluentIcons.more_horizontal_24_filled, color: primaryColor),
      onSelected: (String value) {
        switch (value) {
          case 'like':
            if (playlistId != null) {
              final newValue = !playlistLikeStatus.value;
              playlistLikeStatus.value = newValue;
              updatePlaylistLikeStatus(playlistId!, newValue);
              currentLikedPlaylistsLength.value += newValue ? 1 : -1;
            }
            break;
          case 'delete':
            if (onDelete != null) onDelete!();
            break;
          case 'moveToFolder':
            _showMoveToFolderDialog(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          if (onDelete == null)
            PopupMenuItem<String>(
              value: 'like',
              child: Row(
                children: [
                  Icon(
                    likeStatusToIconMapper[playlistLikeStatus.value],
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    playlistLikeStatus.value
                        ? context.l10n!.removeFromLikedPlaylists
                        : context.l10n!.addToLikedPlaylists,
                  ),
                ],
              ),
            ),
          if (playlistData != null &&
              !isFolder &&
              (playlistData!['source'] == 'user-created' ||
                  playlistData!['source'] == 'user-youtube'))
            PopupMenuItem<String>(
              value: 'moveToFolder',
              child: Row(
                children: [
                  Icon(FluentIcons.folder_24_filled, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(context.l10n!.moveToFolder),
                ],
              ),
            ),
          if (onDelete != null)
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    FluentIcons.delete_24_filled,
                    color:
                        isFolder
                            ? Theme.of(context).colorScheme.error
                            : primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFolder
                        ? context.l10n!.deleteFolder
                        : context.l10n!.deletePlaylist,
                    style:
                        isFolder
                            ? TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            )
                            : null,
                  ),
                ],
              ),
            ),
        ];
      },
    );
  }

  void _showMoveToFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n!.moveToFolder),
          content: SizedBox(
            width: double.maxFinite,
            child: ValueListenableBuilder<List>(
              valueListenable: userPlaylistFolders,
              builder: (context, folders, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Option to remove from folder (move to main library)
                    ListTile(
                      leading: Icon(
                        FluentIcons.library_24_filled,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(context.l10n!.library),
                      onTap: () {
                        Navigator.pop(context);
                        if (playlistData != null) {
                          movePlaylistToFolder(playlistData!, null, context);
                        }
                      },
                    ),
                    const Divider(),
                    // List of available folders
                    if (folders.isNotEmpty)
                      ...folders.map((folder) {
                        return ListTile(
                          leading: Icon(
                            FluentIcons.folder_24_filled,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(folder['name']),
                          onTap: () {
                            Navigator.pop(context);
                            if (playlistData != null) {
                              movePlaylistToFolder(
                                playlistData!,
                                folder['id'],
                                context,
                              );
                            }
                          },
                        );
                      })
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          context.l10n!.noCustomPlaylists,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(180),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n!.cancel),
            ),
          ],
        );
      },
    );
  }

  // Helper methods for folder display
  Widget _buildFolderIcon(Color primaryColor) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(FluentIcons.folder_24_filled, color: primaryColor, size: 24),
    );
  }

  Widget? _buildFolderSubtitle(BuildContext context) {
    if (!isFolder || playlistData == null) return null;

    final playlistCount = (playlistData!['playlists'] as List?)?.length ?? 0;
    return Text(
      playlistCount == 1
          ? '1 ${context.l10n!.playlist.toLowerCase()}'
          : '$playlistCount ${context.l10n!.playlists.toLowerCase()}',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
        fontSize: 12,
      ),
    );
  }

  VoidCallback? _getDefaultOnPressed(
    BuildContext context,
    Map<dynamic, dynamic>? updatedPlaylist,
  ) {
    if (isFolder && playlistData != null) {
      return () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PlaylistFolderPage(
                  folderId: playlistData!['id'],
                  folderName: playlistTitle,
                ),
          ),
        );
      };
    } else {
      return () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PlaylistPage(
                  playlistId: playlistId,
                  playlistData: updatedPlaylist ?? playlistData,
                ),
          ),
        ).then((isPlaylistUpdated) {
          if (playlistId != null &&
              isPlaylistUpdated != null &&
              isPlaylistUpdated) {
            getPlaylistInfoForWidget(
              playlistId,
            ).then((result) => {updatedPlaylist = result});
          }
        });
      };
    }
  }
}
