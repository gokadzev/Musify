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
import 'package:musify/services/common_services.dart';
import 'package:musify/services/playlist_download_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/offline_playlist_dialogs.dart';

/// Downloads a playlist for offline playback, showing the download progress
/// and turning into a "remove offline" button once every song is stored.
///
/// Shared by the playlist page and the artist page: the artist page only has
/// its top songs on screen, so [resolvePlaylist] is what actually produces the
/// songs to download, and it is only called when the button is pressed.
class PlaylistDownloadButton extends StatefulWidget {
  const PlaylistDownloadButton({
    super.key,
    required this.playlistId,
    required this.resolvePlaylist,
    this.songs,
  });

  final String playlistId;

  /// Loads the playlist together with its songs, on demand.
  final Future<Map?> Function() resolvePlaylist;

  /// The songs already on screen, when the caller has the whole list. Without
  /// them the button falls back to whether the playlist was downloaded.
  final List? songs;

  @override
  State<PlaylistDownloadButton> createState() => _PlaylistDownloadButtonState();
}

class _PlaylistDownloadButtonState extends State<PlaylistDownloadButton> {
  /// Whether the songs to download are still being read. On a page that does
  /// not hold them that is a whole discography, and nothing about the button
  /// would say so, so a second tap would read all of it a second time.
  bool _isResolving = false;

  String get playlistId => widget.playlistId;

  bool get _isOffline => widget.songs != null
      ? isPlaylistFullyOffline(widget.songs!)
      : offlinePlaylistService.isPlaylistDownloaded(playlistId);

  @override
  Widget build(BuildContext context) {
    if (playlistId.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<List>(
      valueListenable: userOfflineSongs,
      builder: (context, _, __) => ValueListenableBuilder<List>(
        valueListenable: offlinePlaylistService.offlinePlaylists,
        builder: (context, __, ___) {
          if (_isOffline) {
            return IconButton.filled(
              icon: Icon(
                FluentIcons.arrow_download_off_24_filled,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              iconSize: 24,
              onPressed: () =>
                  showRemoveOfflinePlaylistDialog(context, playlistId),
              tooltip: context.l10n!.removeOffline,
            );
          }

          return ValueListenableBuilder<DownloadProgress>(
            valueListenable: offlinePlaylistService.getProgressNotifier(
              playlistId,
            ),
            builder: (context, progress, _) {
              if (offlinePlaylistService.isPlaylistDownloading(playlistId)) {
                return _buildProgress(context, progress);
              }

              if (offlineMode.value) return const SizedBox.shrink();

              if (_isResolving) {
                return const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                );
              }

              return IconButton.filledTonal(
                icon: const Icon(FluentIcons.arrow_download_24_filled),
                iconSize: 24,
                onPressed: () => _download(context),
                tooltip: context.l10n!.downloadPlaylist,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProgress(BuildContext context, DownloadProgress progress) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress.isCancelled ? null : progress.progress,
              strokeWidth: 3,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          if (!progress.isCancelled)
            IconButton(
              icon: const Icon(FluentIcons.dismiss_24_filled, size: 16),
              onPressed: () =>
                  offlinePlaylistService.cancelDownload(context, playlistId),
              tooltip: context.l10n!.cancel,
            ),
        ],
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    if (_isResolving) return;

    setState(() => _isResolving = true);
    Map? playlist;
    try {
      playlist = await widget.resolvePlaylist();
    } catch (_) {
      if (context.mounted) showToast(context, context.l10n!.error);
      return;
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
    if (!context.mounted) return;

    if (playlist == null) {
      showToast(context, context.l10n!.error);
      return;
    }

    await offlinePlaylistService.downloadPlaylist(context, playlist);
  }
}
