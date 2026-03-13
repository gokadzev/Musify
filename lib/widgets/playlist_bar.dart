/*
 *     Copyright (C) 2026 Valeri Gokadze
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

import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/constants/common_variables.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/utilities/artwork_provider.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/edit_playlist_dialog.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    Map<dynamic, dynamic>? updatedPlaylist;
    return Padding(
      padding: commonBarPadding,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? _getDefaultOnPressed(context, updatedPlaylist),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            child: Row(
              children: [
                if (isFolder)
                  _buildFolderIcon(colorScheme)
                else
                  _buildPlaylistIcon(colorScheme),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        playlistTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isFolder) ...[
                        const SizedBox(height: 3),
                        _buildFolderSubtitle(context) ??
                            const SizedBox.shrink(),
                      ],
                    ],
                  ),
                ),
                if (showBuildActions) ...[
                  const SizedBox(width: 4),
                  _buildActionButtons(context, colorScheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistIcon(ColorScheme colorScheme) {
    if (playlistArtwork != null && playlistArtwork!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(
          image: ArtworkProvider.get(playlistArtwork!),
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildIconFallback(colorScheme),
        ),
      );
    }
    return _buildIconFallback(colorScheme);
  }

  Widget _buildIconFallback(ColorScheme colorScheme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(cubeIcon, size: 26, color: colorScheme.onSecondaryContainer),
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHigh,
      icon: Icon(
        FluentIcons.more_vertical_24_regular,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
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
          case 'edit':
            _handleEdit(context);
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
                    color: colorScheme.primary,
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
                  Icon(
                    FluentIcons.folder_24_filled,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(context.l10n!.moveToFolder),
                ],
              ),
            ),
          if (playlistData != null &&
              !isFolder &&
              playlistData!['source'] == 'user-created')
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(FluentIcons.edit_24_filled, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(context.l10n!.editPlaylist),
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
                    color: isFolder ? colorScheme.error : colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFolder
                        ? context.l10n!.deleteFolder
                        : context.l10n!.deletePlaylist,
                    style: isFolder
                        ? TextStyle(color: colorScheme.error)
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
                          title: Text(
                            folder['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
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
                          context.l10n!.noFolders,
                          style: TextStyle(color: Theme.of(context).hintColor),
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
  Widget _buildFolderIcon(ColorScheme colorScheme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        FluentIcons.folder_24_filled,
        size: 26,
        color: colorScheme.onSecondaryContainer,
      ),
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
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  VoidCallback? _getDefaultOnPressed(
    BuildContext context,
    Map<dynamic, dynamic>? updatedPlaylist,
  ) {
    if (isFolder && playlistData != null) {
      return () {
        context.push(
          '/home/folder/${playlistData!['id']}/${Uri.encodeComponent(playlistTitle)}',
        );
      };
    } else {
      return () {
        final resolvedPlaylistId =
            playlistId ?? playlistData?['ytid']?.toString();
        if (resolvedPlaylistId == null ||
            resolvedPlaylistId.isEmpty ||
            resolvedPlaylistId == 'null') {
          showToast(context, context.l10n!.error);
          return;
        }
        context.push('/home/playlist/$resolvedPlaylistId');
      };
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    if (playlistData == null) return;

    final result = await showDialog<Map?>(
      context: context,
      builder: (context) => EditPlaylistDialog(playlistData: playlistData!),
    );

    if (result != null) {
      final index = userCustomPlaylists.value.indexOf(playlistData);
      if (index != -1) {
        final updatedPlaylists = List<Map>.from(userCustomPlaylists.value);
        updatedPlaylists[index] = result;
        userCustomPlaylists.value = updatedPlaylists;
        unawaited(
          addOrUpdateData('user', 'customPlaylists', userCustomPlaylists.value),
        );
        final appCtx = NavigationManager().context;
        showToast(appCtx, appCtx.l10n!.playlistUpdated);
      }
    }
  }
}
