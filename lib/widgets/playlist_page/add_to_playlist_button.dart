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
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/playlist_dialogs.dart';

/// Adds every song of a resolved playlist to one of the user's playlists.
///
/// The artist landing page only has its ranked songs on screen, so resolving
/// on demand is what makes this action share the complete "All songs" catalog.
class PlaylistAddToPlaylistButton extends StatefulWidget {
  const PlaylistAddToPlaylistButton({super.key, required this.resolvePlaylist});

  final Future<Map?> Function() resolvePlaylist;

  @override
  State<PlaylistAddToPlaylistButton> createState() =>
      _PlaylistAddToPlaylistButtonState();
}

class _PlaylistAddToPlaylistButtonState
    extends State<PlaylistAddToPlaylistButton> {
  bool _isResolving = false;

  @override
  Widget build(BuildContext context) {
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
      icon: const Icon(FluentIcons.album_add_24_regular),
      iconSize: 24,
      onPressed: _resolveAndAdd,
      tooltip: context.l10n!.addToPlaylist,
    );
  }

  Future<void> _resolveAndAdd() async {
    if (_isResolving) return;
    setState(() => _isResolving = true);

    Map? playlist;
    try {
      playlist = await widget.resolvePlaylist();
    } catch (_) {
      if (mounted) showToast(context, context.l10n!.error);
      return;
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
    if (!mounted) return;

    if (playlist == null || playlist['list'] is! List) {
      showToast(context, context.l10n!.error);
      return;
    }

    final songs = playlist['list'] as List;
    if (songs.isEmpty) {
      showToast(context, context.l10n!.noSongsInPlaylist);
      return;
    }

    showAddToPlaylistDialog(context, songs: songs);
  }
}
