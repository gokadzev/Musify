import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/delayed_display.dart';

class PlaylistCube extends StatelessWidget {
  PlaylistCube({
    super.key,
    this.id,
    this.image,
    required this.title,
    this.onClickOpen = true,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
    this.zoomNumber = 0.5,
  });
  final String? id;
  final dynamic image;
  final String title;
  final bool onClickOpen;
  final IconData cubeIcon;
  final double zoomNumber;

  final likeStatusToIconMapper = {
    true: FluentIcons.star_24_filled,
    false: FluentIcons.star_24_regular
  };

  late final playlistLikeStatus =
      ValueNotifier<bool>(isPlaylistAlreadyLiked(id));

  @override
  Widget build(BuildContext context) {
    final calculatedSize = context.screenSize.width * zoomNumber;
    return Stack(
      children: <Widget>[
        DelayedDisplay(
          delay: const Duration(milliseconds: 200),
          fadingDuration: const Duration(milliseconds: 400),
          child: GestureDetector(
            onTap: onClickOpen && id != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistPage(playlistId: id),
                      ),
                    );
                  }
                : () => {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: image != null
                  ? CachedNetworkImage(
                      height: calculatedSize,
                      width: calculatedSize,
                      imageUrl: image.toString(),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          noImageCube(calculatedSize),
                    )
                  : noImageCube(calculatedSize),
            ),
          ),
        ),
        if (id != null)
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
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                title,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
