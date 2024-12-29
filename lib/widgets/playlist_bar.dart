import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/widgets/no_artwork_cube.dart';

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

  static const double paddingValue = 4;
  static const double likeButtonOffset = 5;
  static const double artworkSize = 60;
  static const double iconSize = 27;
  static const double albumTextFontSize = 12;

  final ValueNotifier<bool> playlistLikeStatus;

  static const likeStatusToIconMapper = {
    true: FluentIcons.heart_24_filled,
    false: FluentIcons.heart_24_regular,
  };

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: commonBarPadding,
      child: GestureDetector(
        onTap: onPressed ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistPage(
                    playlistId: playlistId,
                    playlistData: playlistData,
                  ),
                ),
              );
            },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          margin: const EdgeInsets.only(bottom: 3),
          child: Padding(
            padding: commonBarContentPadding,
            child: Row(
              children: [
                _buildAlbumArt(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        playlistTitle,
                        overflow: TextOverflow.ellipsis,
                        style:
                            commonBarTitleStyle.copyWith(color: primaryColor),
                      ),
                    ],
                  ),
                ),
                if (showBuildActions)
                  _buildActionButtons(context, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return playlistArtwork != null
        ? CachedNetworkImage(
            key: Key(playlistArtwork.toString()),
            height: artworkSize,
            width: artworkSize,
            imageUrl: playlistArtwork.toString(),
            fit: BoxFit.cover,
            imageBuilder: (context, imageProvider) => SizedBox(
              width: artworkSize,
              height: artworkSize,
              child: ClipRRect(
                borderRadius: commonBarRadius,
                child: Image(
                  image: imageProvider,
                ),
              ),
            ),
            errorWidget: (context, url, error) => NullArtworkWidget(
              icon: cubeIcon,
              iconSize: iconSize,
              size: artworkSize,
            ),
          )
        : NullArtworkWidget(
            icon: cubeIcon,
            iconSize: iconSize,
            size: artworkSize,
          );
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).colorScheme.surface,
      icon: Icon(
        FluentIcons.more_horizontal_24_filled,
        color: primaryColor,
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
          case 'remove':
            if (onDelete != null) onDelete!();
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
          if (onDelete != null)
            PopupMenuItem<String>(
              value: 'remove',
              child: Row(
                children: [
                  Icon(FluentIcons.delete_24_filled, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(context.l10n!.deletePlaylist),
                ],
              ),
            ),
        ];
      },
    );
  }
}
