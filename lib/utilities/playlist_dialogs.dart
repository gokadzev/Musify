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
            title: Text(
              context.l10n!.addPlaylist,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
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
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.l10n!.cancel,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
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
      return AlertDialog(
        icon: const Icon(FluentIcons.album_add_24_filled),
        title: Text(context.l10n!.addToPlaylist),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: Builder(
            builder: (context) {
              final playlists = getUserCustomPlaylists();
              return playlists.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return Card(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          elevation: 0,
                          child: ListTile(
                            title: Text(playlist['title']),
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
                        );
                      },
                    )
                  : Text(
                      context.l10n!.noCustomPlaylists,
                      textAlign: TextAlign.center,
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
