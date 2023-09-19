import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/style/app_themes.dart';

class PlaylistCube extends StatelessWidget {
  PlaylistCube({
    super.key,
    this.id,
    this.playlistData,
    this.image,
    required this.title,
    this.onClickOpen = true,
    this.showFavoriteButton = true,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
    this.size = 220,
    this.zoomNumber = 0.5,
  });

  final String? id;
  final dynamic playlistData;
  final dynamic image;
  final String title;
  final bool onClickOpen;
  final bool showFavoriteButton;
  final IconData cubeIcon;
  final double size;
  final double zoomNumber;

  final likeStatusToIconMapper = {
    true: FluentIcons.star_24_filled,
    false: FluentIcons.star_24_regular,
  };

  late final playlistLikeStatus =
      ValueNotifier<bool>(isPlaylistAlreadyLiked(id));

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: onClickOpen && (id != null || playlistData != null)
              ? () {
                  if (id != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistPage(playlistId: id),
                      ),
                    );
                  } else if (playlistData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PlaylistPage(playlistData: playlistData),
                      ),
                    );
                  }
                }
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: image != null
                ? CachedNetworkImage(
                    height: size,
                    width: size,
                    imageUrl: image.toString(),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => noImageCube(size),
                  )
                : noImageCube(size),
          ),
        ),
        if (id != null && showFavoriteButton)
          ValueListenableBuilder<bool>(
            valueListenable: playlistLikeStatus,
            builder: (_, value, __) {
              return Positioned(
                bottom: 5,
                right: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () {
                      playlistLikeStatus.value = !playlistLikeStatus.value;
                      updatePlaylistLikeStatus(
                        id,
                        image,
                        title,
                        playlistLikeStatus.value,
                      );
                      currentLikedPlaylistsLength.value = value
                          ? currentLikedPlaylistsLength.value + 1
                          : currentLikedPlaylistsLength.value - 1;
                    },
                    icon: Icon(
                      likeStatusToIconMapper[value],
                      color: colorScheme.primary,
                      size: 25,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget noImageCube(double calculatedSize) {
    return Container(
      height: calculatedSize,
      width: calculatedSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colorScheme.secondary,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              cubeIcon,
              size: 30,
              color: colorScheme.surface,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
