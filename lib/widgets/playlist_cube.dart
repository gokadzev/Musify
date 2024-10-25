/*
 *     Copyright (C) 2024 Valeri Gokadze
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/widgets/no_artwork_cube.dart';

class PlaylistCube extends StatelessWidget {
  PlaylistCube(
    this.playlist, {
    super.key,
    this.playlistData,
    this.onClickOpen = true,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
    this.size = 220,
    this.borderRadius = 13,
    this.isAlbum = false,
  }) : playlistLikeStatus = ValueNotifier<bool>(
          isPlaylistAlreadyLiked(playlist['ytid']),
        );

  final Map? playlistData;
  final Map playlist;
  final bool onClickOpen;
  final IconData cubeIcon;
  final double size;
  final double borderRadius;
  final bool? isAlbum;

  static const double paddingValue = 4;
  static const double likeButtonOffset = 5;
  static const double iconSize = 30;
  static const double albumTextFontSize = 12;

  final ValueNotifier<bool> playlistLikeStatus;

  static const likeStatusToIconMapper = {
    true: FluentIcons.heart_24_filled,
    false: FluentIcons.heart_24_regular,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryColor = colorScheme.secondary;
    final onSecondaryColor = colorScheme.onSecondary;

    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap:
              onClickOpen && (playlist['ytid'] != null || playlistData != null)
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistPage(
                            playlistId: playlist['ytid'],
                            playlistData: playlistData,
                          ),
                        ),
                      );
                    }
                  : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: playlist['image'] != null
                ? CachedNetworkImage(
                    key: Key(playlist['image'].toString()),
                    height: size,
                    width: size,
                    imageUrl: playlist['image'].toString(),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => NullArtworkWidget(
                      icon: cubeIcon,
                      iconSize: iconSize,
                      size: size,
                      title: playlist['title'],
                    ),
                  )
                : NullArtworkWidget(
                    icon: cubeIcon,
                    iconSize: iconSize,
                    size: size,
                    title: playlist['title'],
                  ),
          ),
        ),
        if (isAlbum ?? false)
          Positioned(
            top: likeButtonOffset,
            right: likeButtonOffset,
            child: Container(
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(paddingValue),
              ),
              padding: const EdgeInsets.all(paddingValue),
              child: Text(
                context.l10n!.album,
                style: TextStyle(
                  color: onSecondaryColor,
                  fontSize: albumTextFontSize,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
