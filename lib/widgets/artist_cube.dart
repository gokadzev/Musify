import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/shimmer.dart';

class ArtistCube extends StatefulWidget {
  const ArtistCube(
    this.artist, {
    this.borderRadius = 150,
    this.borderRadiusInner = 10,
    this.iconSize = 30,
  });

  final String artist;
  final double borderRadius;
  final double borderRadiusInner;
  final double iconSize;

  @override
  _ArtistCubeState createState() => _ArtistCubeState();
}

class _ArtistCubeState extends State<ArtistCube>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final calculatedSize = MediaQuery.of(context).size.height * 0.25;

    return FutureBuilder<String?>(
      future: getArtistArtwork(widget.artist),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: colorScheme.primary.withOpacity(0.5),
            highlightColor: colorScheme.primary.withOpacity(0.2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Container(
                color: colorScheme.primary,
                width: calculatedSize,
                height: calculatedSize,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final artworkUrl = snapshot.data;

          if (artworkUrl != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: CachedNetworkImage(
                imageUrl: artworkUrl,
                width: calculatedSize,
                height: calculatedSize,
                fit: BoxFit.cover,
              ),
            );
          } else {
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Container(
                height: calculatedSize,
                width: calculatedSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  color: colorScheme.secondary,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        FluentIcons.person_24_regular,
                        size: widget.iconSize,
                        color: colorScheme.surface,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          widget.artist,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }
}
