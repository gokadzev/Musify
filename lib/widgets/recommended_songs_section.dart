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
import 'package:musify/constants/app_constants.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/widgets/section_header.dart';
import 'package:musify/widgets/song_bar.dart';

/// A titled list of recommended songs with an optional "play all" button.
///
/// Shared by the home screen ("recommended for you") and the per-playlist
/// "recommended songs" section so both render identically.
class RecommendedSongsSection extends StatelessWidget {
  const RecommendedSongsSection({
    super.key,
    required this.title,
    required this.songs,
    required this.listKeyPrefix,
    this.showPlayButton = true,
    this.onAddSong,
  });

  final String title;
  final List<dynamic> songs;

  /// Scope passed to [listItemKey] so each usage keeps stable, distinct keys.
  final String listKeyPrefix;
  final bool showPlayButton;

  /// When set, each row shows a single "add" button (via [SongBar.onAdd])
  /// instead of the full song overflow menu.
  final void Function(Map song)? onAddSong;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: title,
          icon: FluentIcons.sparkle_24_filled,
          actionButton: showPlayButton
              ? IconButton(
                  onPressed: () async {
                    await audioHandler.playPlaylistSong(
                      playlist: {'title': title, 'list': songs},
                      songIndex: 0,
                    );
                  },
                  icon: Icon(
                    FluentIcons.play_circle_24_filled,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                )
              : null,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: songs.length,
          padding: commonListViewBottomPadding,
          itemBuilder: (context, index) {
            final song = songs[index];
            final borderRadius = getItemBorderRadius(index, songs.length);
            return RepaintBoundary(
              key: listItemKey(listKeyPrefix, index, song),
              child: SongBar(
                song,
                true,
                borderRadius: borderRadius,
                onAdd: onAddSong != null && song is Map
                    ? () => onAddSong!(song)
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}
