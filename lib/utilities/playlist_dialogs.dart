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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/playlist_image_picker.dart';

void showCreatePlaylistDialog(
  BuildContext context, {
  dynamic songToAdd,
  List<dynamic>? songsToAdd,
}) {
  var id = '';
  var customPlaylistName = '';
  var isYouTubeMode = songToAdd == null && songsToAdd == null;
  String? imageUrl;
  String? imageBase64;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, dialogSetState) {
          final colorScheme = Theme.of(context).colorScheme;

          Future<void> _pickImage() async {
            final result = await pickImage();
            if (result != null) {
              dialogSetState(() {
                imageBase64 = result;
                imageUrl = null;
              });
            }
          }

          Widget _imagePreview() {
            return buildImagePreview(
              imageBase64: imageBase64,
              imageUrl: imageUrl,
            );
          }

          return AlertDialog(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            icon: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                FluentIcons.add_24_filled,
                color: colorScheme.primary,
                size: 32,
              ),
            ),
            title: Text(
              context.l10n!.addPlaylist,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            titleTextStyle: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (songToAdd == null && songsToAdd == null)
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                dialogSetState(() {
                                  isYouTubeMode = true;
                                  id = '';
                                  customPlaylistName = '';
                                  imageUrl = null;
                                  imageBase64 = null;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isYouTubeMode
                                      ? colorScheme.primaryContainer
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FluentIcons.globe_20_filled,
                                      size: 20,
                                      color: isYouTubeMode
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'YouTube',
                                      style: TextStyle(
                                        color: isYouTubeMode
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: isYouTubeMode
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                dialogSetState(() {
                                  isYouTubeMode = false;
                                  id = '';
                                  customPlaylistName = '';
                                  imageUrl = null;
                                  imageBase64 = null;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: !isYouTubeMode
                                      ? colorScheme.primaryContainer
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FluentIcons.person_20_filled,
                                      size: 20,
                                      color: !isYouTubeMode
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.l10n!.custom,
                                      style: TextStyle(
                                        color: !isYouTubeMode
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: !isYouTubeMode
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (isYouTubeMode)
                    TextField(
                      decoration: InputDecoration(
                        labelText: context.l10n!.youtubePlaylistLinkOrId,
                        prefixIcon: Icon(
                          FluentIcons.link_20_regular,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                      ),
                      onChanged: (value) {
                        id = value;
                      },
                    )
                  else ...[
                    TextField(
                      decoration: InputDecoration(
                        labelText: context.l10n!.customPlaylistName,
                        prefixIcon: Icon(
                          FluentIcons.text_field_20_regular,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                      ),
                      autofocus: true,
                      onChanged: (value) {
                        customPlaylistName = value;
                      },
                    ),
                    if (imageBase64 == null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: context.l10n!.customPlaylistImgUrl,
                          prefixIcon: Icon(
                            FluentIcons.image_20_regular,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLow,
                        ),
                        onChanged: (value) {
                          imageUrl = value;
                          imageBase64 = null;
                          dialogSetState(() {});
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (imageUrl == null) ...[
                      buildImagePickerRow(
                        context,
                        _pickImage,
                        imageBase64 != null,
                      ),
                      _imagePreview(),
                    ],
                  ],
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.l10n!.cancel),
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (isYouTubeMode && id.isNotEmpty) {
                    final result = await addUserPlaylist(id, context);
                    if (context.mounted) showToast(context, result);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } else if (!isYouTubeMode && customPlaylistName.isNotEmpty) {
                    final (result, newPlaylistId) = createCustomPlaylist(
                      customPlaylistName.trim(),
                      imageBase64 ?? imageUrl,
                      context,
                    );
                    if (songToAdd != null) {
                      if (context.mounted) {
                        final addResult = addSongInCustomPlaylist(
                          context,
                          newPlaylistId,
                          songToAdd,
                        );
                        showToast(context, addResult);
                      }
                    } else if (songsToAdd != null && songsToAdd.isNotEmpty) {
                      if (context.mounted) {
                        final addResult = addSongsInCustomPlaylist(
                          context,
                          newPlaylistId,
                          songsToAdd,
                        );
                        showToast(context, addResult);
                      }
                    } else {
                      if (context.mounted) showToast(context, result);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } else {
                    showToast(
                      context,
                      '${context.l10n!.provideIdOrNameError}.',
                    );
                  }
                },
                icon: const Icon(FluentIcons.add_20_filled),
                label: Text(context.l10n!.add),
              ),
            ],
          );
        },
      );
    },
  );
}

void showAddToPlaylistDialog(
  BuildContext context, {
  dynamic song,
  List<dynamic>? songs,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;
      return AlertDialog(
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            FluentIcons.album_add_24_filled,
            color: colorScheme.secondary,
            size: 28,
          ),
        ),
        title: Text(
          context.l10n!.addToPlaylist,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: Builder(
            builder: (context) {
              final folders = userPlaylistFolders.value
                  .where(
                    (folder) =>
                        folder['playlists'] != null &&
                        (folder['playlists'] as List).isNotEmpty,
                  )
                  .toList();
              final topLevelPlaylists = getPlaylistsNotInFolders();

              final hasAny =
                  (folders.isNotEmpty) || (topLevelPlaylists.isNotEmpty);

              if (!hasAny) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      context.l10n!.noCustomPlaylists,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Folders as expansion tiles
                  for (final folder in folders)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Material(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              FluentIcons.folder_24_regular,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            folder['name'] ?? '',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          children: [
                            for (final p
                                in (folder['playlists'] as List? ?? []))
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                ),
                                child: _AddToPlaylistItem(
                                  icon: FluentIcons.music_note_2_24_regular,
                                  iconColor: Theme.of(
                                    context,
                                  ).colorScheme.tertiary,
                                  iconBgColor: Theme.of(
                                    context,
                                  ).colorScheme.tertiaryContainer,
                                  label: p['title'] ?? '',
                                  onTap: () {
                                    if (song != null) {
                                      showToast(
                                        context,
                                        addSongInCustomPlaylist(
                                          context,
                                          p['ytid'],
                                          song,
                                        ),
                                      );
                                    } else if (songs != null &&
                                        songs.isNotEmpty) {
                                      showToast(
                                        context,
                                        addSongsInCustomPlaylist(
                                          context,
                                          p['ytid'],
                                          songs,
                                        ),
                                      );
                                    }
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Top-level playlists
                  if (topLevelPlaylists.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final playlist in topLevelPlaylists)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _AddToPlaylistItem(
                          icon: FluentIcons.music_note_2_24_regular,
                          iconColor: Theme.of(context).colorScheme.tertiary,
                          iconBgColor: Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer,
                          label: playlist['title'] ?? '',
                          onTap: () {
                            if (song != null) {
                              showToast(
                                context,
                                addSongInCustomPlaylist(
                                  context,
                                  playlist['ytid'],
                                  song,
                                ),
                              );
                            } else if (songs != null && songs.isNotEmpty) {
                              showToast(
                                context,
                                addSongsInCustomPlaylist(
                                  context,
                                  playlist['ytid'],
                                  songs,
                                ),
                              );
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            child: Text(context.l10n!.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showCreatePlaylistDialog(
                context,
                songToAdd: song,
                songsToAdd: songs,
              );
            },
            icon: const Icon(FluentIcons.add_24_regular, size: 18),
            label: Text(context.l10n!.addPlaylist),
          ),
        ],
      );
    },
  );
}

class _AddToPlaylistItem extends StatelessWidget {
  const _AddToPlaylistItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  FluentIcons.chevron_right_24_regular,
                  color: colorScheme.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
