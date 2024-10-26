import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/services/settings_manager.dart';
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
    this.onLongPress,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
    this.isAlbum = false,
  }) : playlistLikeStatus = ValueNotifier<bool>(
          isPlaylistAlreadyLiked(playlistId),
        );

  final Map? playlistData;
  final String? playlistId;
  final String playlistTitle;
  final String? playlistArtwork;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final IconData cubeIcon;
  final bool? isAlbum;

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
        onLongPress: onLongPress,
        child: Card(
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(8),
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
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!offlineMode.value)
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: playlistLikeStatus,
                builder: (_, value, __) {
                  return IconButton(
                    color: primaryColor,
                    icon: Icon(likeStatusToIconMapper[value]),
                    onPressed: () {
                      if (playlistId != null) {
                        final newValue = !playlistLikeStatus.value;
                        playlistLikeStatus.value = newValue;
                        updatePlaylistLikeStatus(playlistId!, newValue);
                        currentLikedPlaylistsLength.value += newValue ? 1 : -1;
                      }
                    },
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}
