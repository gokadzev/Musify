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
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/playlist_bar.dart';

class PlaylistFolderPage extends StatefulWidget {
  const PlaylistFolderPage({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  final String folderId;
  final String folderName;

  @override
  State<PlaylistFolderPage> createState() => _PlaylistFolderPageState();
}

class _PlaylistFolderPageState extends State<PlaylistFolderPage> {
  late String _folderName;

  @override
  void initState() {
    super.initState();
    _folderName = widget.folderName;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List>(
      valueListenable: userPlaylistFolders,
      builder: (context, _, __) {
        final playlists = getPlaylistsInFolder(widget.folderId);
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 300,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _buildHeader(context, playlists.length),
                ),
                actions: [
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'add',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FluentIcons.add_24_regular,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(context.l10n!.addPlaylist),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'rename',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FluentIcons.edit_24_regular,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(context.l10n!.editFolder),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FluentIcons.delete_24_regular,
                              color: Theme.of(context).colorScheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.l10n!.deleteFolder,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'add') {
                        _showAddPlaylistDialog();
                      } else if (value == 'rename') {
                        _showRenameFolderDialog();
                      } else if (value == 'delete') {
                        _showDeleteFolderDialog();
                      }
                    },
                  ),
                ],
              ),
              if (playlists.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: commonListViewBottomPadding,
                  sliver: SliverList.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final borderRadius = getItemBorderRadius(
                        index,
                        playlists.length,
                      );
                      return PlaylistBar(
                        key: listItemKey('folder_playlist', index, playlist),
                        playlist['title'],
                        playlistId: playlist['ytid'],
                        playlistArtwork: playlist['image'],
                        playlistData: playlist,
                        onDelete: () => _showRemovePlaylistDialog(playlist),
                        borderRadius: borderRadius,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int playlistCount) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipPath(
            clipper: const ShapeBorderClipper(
              shape: StarBorder(
                points: 8,
                pointRounding: 0.8,
                valleyRounding: 0.2,
                innerRadiusRatio: 0.6,
              ),
            ),
            child: Container(
              width: 130,
              height: 130,
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                FluentIcons.folder_24_filled,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _folderName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FluentIcons.music_note_2_24_regular,
                  size: 14,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  playlistCount == 1
                      ? '1 ${context.l10n!.playlist.toLowerCase()}'
                      : '$playlistCount ${context.l10n!.playlists.toLowerCase()}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.folder_24_regular,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n!.emptyFolderMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPlaylistDialog() async {
    final customCandidates = getPlaylistsNotInFolders();
    final youtubeCandidates = await getUserPlaylistsNotInFolders();
    final candidates = [...customCandidates, ...youtubeCandidates];

    if (!mounted) return;

    if (candidates.isEmpty) {
      showToast(context, context.l10n!.noPlaylistsAdded);
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n!.addPlaylist),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final playlist = candidates[index];
              return ListTile(
                leading: Icon(
                  FluentIcons.music_note_2_24_regular,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  playlist['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(context);
                  movePlaylistToFolder(playlist, widget.folderId, context);
                },
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
      ),
    );
  }

  void _showRemovePlaylistDialog(Map playlist) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        submitMessage: context.l10n!.remove,
        confirmationMessage: context.l10n!.removeFromFolder,
        onCancel: () => Navigator.of(context).pop(),
        onSubmit: () {
          Navigator.of(context).pop();
          movePlaylistToFolder(playlist, null, context);
        },
      ),
    );
  }

  void _showRenameFolderDialog() {
    var newName = _folderName;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Icon(
          FluentIcons.folder_24_regular,
          color: colorScheme.primary,
          size: 32,
        ),
        title: Text(
          context.l10n!.editFolder,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextFormField(
          decoration: InputDecoration(
            labelText: context.l10n!.folderName,
            prefixIcon: Icon(
              FluentIcons.text_field_20_regular,
              color: colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
          ),
          initialValue: newName,
          autofocus: true,
          onChanged: (value) => newName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n!.cancel,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              final result = renamePlaylistFolder(
                widget.folderId,
                newName,
                context,
              );
              showToast(context, result);
              if (newName.trim().isNotEmpty) {
                setState(() => _folderName = newName.trim());
              }
            },
            icon: const Icon(FluentIcons.save_20_filled),
            label: Text(context.l10n!.update),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        submitMessage: context.l10n!.delete,
        confirmationMessage: context.l10n!.deleteFolderQuestion,
        onCancel: () => Navigator.of(context).pop(),
        onSubmit: () {
          Navigator.of(context).pop();
          deletePlaylistFolder(widget.folderId, context);
          Navigator.of(context).pop(); // Go back to library
        },
      ),
    );
  }
}
