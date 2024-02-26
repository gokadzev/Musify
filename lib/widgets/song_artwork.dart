import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify/widgets/no_artwork_cube.dart';
import 'package:musify/widgets/spinner.dart';

class SongArtworkWidget extends StatelessWidget {
  const SongArtworkWidget({
    super.key,
    required this.size,
    required this.metadata,
    this.borderRadius = 10.0,
    this.errorWidgetIconSize = 20.0,
  });
  final double size;
  final MediaItem metadata;
  final double borderRadius;
  final double errorWidgetIconSize;

  @override
  Widget build(BuildContext context) {
    return metadata.artUri?.scheme == 'file'
        ? SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.file(
                File(metadata.extras?['artWorkPath']),
                fit: BoxFit.cover,
              ),
            ),
          )
        : CachedNetworkImage(
            width: size,
            height: size,
            imageUrl: metadata.artUri.toString(),
            imageBuilder: (context, imageProvider) => ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
            placeholder: (context, url) => const Spinner(),
            errorWidget: (context, url, error) => NullArtworkWidget(
              iconSize: errorWidgetIconSize,
            ),
          );
  }
}
