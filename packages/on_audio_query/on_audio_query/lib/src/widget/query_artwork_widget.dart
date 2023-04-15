/*
=============
Author: Lucas Josino
Github: https://github.com/LucJosin
Website: https://www.lucasjosino.com/
=============
Plugin/Id: on_audio_query#0
Homepage: https://github.com/LucJosin/on_audio_query
Pub: https://pub.dev/packages/on_audio_query
License: https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/LICENSE
Copyright: © 2021, Lucas Josino. All rights reserved.
=============
*/

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';

import '../on_audio_query_controller.dart';

/// Widget that will help to "query" artwork for song/album.
///
/// A simple example on how you can use the [queryArtwork].
///
/// See more: [QueryArtworkWidget](https://pub.dev/documentation/on_audio_query/latest/on_audio_query/QueryArtworkWidget-class.html)
class QueryArtworkWidget extends StatelessWidget {
  /// Used to find and get image.
  ///
  /// All Audio/Song has a unique [id].
  final int id;

  /// Used to define artwork [type].
  ///
  /// Opts: [AUDIO] and [ALBUM].
  final ArtworkType type;

  @Deprecated('Deprecated after [3.0.0]. Use [formatType] instead')
  final ArtworkFormat? format;

  /// Used to define artwork [formatType].
  ///
  /// Opts: [JPEG] and [PNG].
  ///
  /// Important:
  ///
  /// * If [formatType] is null, will be set to [JPEG].
  final ArtworkFormatType formatType;

  /// Used to define artwork [size].
  ///
  /// Important:
  ///
  /// * If [size] is not defined, will be set to [200].
  /// * This value have a directly influence to image quality.
  final int size;

  /// Used to define artwork [quality].
  ///
  /// Important:
  ///
  /// * If [quality] is null, will be set to [100].
  final int quality;

  /// Used to define the artwork [border radius].
  ///
  /// Important:
  ///
  /// * If [artworkBorder] is null, will be set to [50].
  final BorderRadius? artworkBorder;

  /// Used to define the artwork [quality].
  ///
  /// Important:
  ///
  /// * If [artworkQuality] is null, will be set to [low].
  /// * This value [don't] have a directly influence to image quality.
  final FilterQuality artworkQuality;

  /// Used to define artwork [width].
  ///
  /// Important:
  ///
  /// * If [artworkWidth] is null, will be set to [50].
  final double artworkWidth;

  /// Used to define artwork [height].
  ///
  /// Important:
  ///
  /// * If [artworkHeight] is null, will be set to [50].
  final double artworkHeight;

  /// Used to define artwork [fit].
  ///
  /// Important:
  ///
  /// * If [artworkFit] is null, will be set to [cover].
  final BoxFit artworkFit;

  /// Used to define artwork [clip].
  ///
  /// Important:
  ///
  /// * If [artworkClipBehavior] is null, will be set to [antiAlias].
  final Clip artworkClipBehavior;

  /// Used to define artwork [scale].
  ///
  /// Important:
  ///
  /// * If [artworkScale] is null, will be set to [1.0].
  final double artworkScale;

  /// Used to define if artwork should [repeat].
  ///
  /// Important:
  ///
  /// * If [artworkRepeat] is null, will be set to [false].
  final ImageRepeat artworkRepeat;

  /// Used to define artwork [color].
  ///
  /// Important:
  ///
  /// * [artworkColor] default value is [null].
  final Color? artworkColor;

  /// Used to define artwork [blend].
  ///
  /// Important:
  ///
  /// * [artworkBlendMode] default value is [null].
  final BlendMode? artworkBlendMode;

  /// Used to define if artwork should [keep] old art even when [Flutter State] change.
  ///
  /// ## Flutter Docs:
  ///
  /// ### Why is the default value of [gaplessPlayback] false?
  ///
  /// Having the default value of [gaplessPlayback] be false helps prevent
  /// situations where stale or misleading information might be presented.
  /// Consider the following case:
  ///
  /// We have constructed a 'Person' widget that displays an avatar [Image] of
  /// the currently loaded person along with their name. We could request for a
  /// new person to be loaded into the widget at any time. Suppose we have a
  /// person currently loaded and the widget loads a new person. What happens
  /// if the [Image] fails to load?
  ///
  /// * Option A ([gaplessPlayback] = false): The new person's name is coupled
  /// with a blank image.
  ///
  /// * Option B ([gaplessPlayback] = true): The widget displays the avatar of
  /// the previous person and the name of the newly loaded person.
  ///
  /// Important:
  ///
  /// * If [keepOldArtwork] is null, will be set to [false].
  final bool keepOldArtwork;

  /// Used to define if artwork should be cached inside the app support directory.
  ///
  /// Note: This parameter will **ONLY** be valid on `Windows` or `IOS` platforms.
  ///
  /// Important:
  ///
  /// * [cacheArtwork] default value is [true].
  final bool cacheArtwork;

  /// Used to define if artwork should be cached **temporarily** inside the
  /// app temp directory.
  ///
  /// Note: This parameter will **ONLY** be valid on `Windows` or `IOS` platforms.
  ///
  /// Note²: This parameter will **ONLY** be used when [cacheArtwork] is true.
  ///
  /// Important:
  ///
  /// * [cacheTemporarily] default value is [true].
  final bool cacheTemporarily;

  /// Used to define if artwork should be overridden if already exists. This will
  /// replace the current artwork with a new one.
  ///
  /// Note: This parameter will **ONLY** be valid on `Windows` or `IOS` platforms.
  ///
  /// Note²: This parameter will **ONLY** be used when [cacheArtwork] is true.
  ///
  /// Important:
  ///
  /// * [overrideCache] default value is [false].
  final bool overrideCache;

  /// Used to define a Widget when audio/song don't return any artwork.
  ///
  /// Important:
  ///
  /// * If [nullArtworkWidget] is null, will be set to [image_not_supported] icon.
  final Widget? nullArtworkWidget;

  /// A builder function that is called if an error occurs during image loading.
  ///
  ///
  /// If this builder is not provided, any exceptions will be reported to
  /// [FlutterError.onError]. If it is provided, the caller should either handle
  /// the exception by providing a replacement widget, or rethrow the exception.
  ///
  /// Important:
  ///
  ///   * If [errorBuilder] is null, will set the [nullArtworkWidget] and if is null
  ///   will be used a icon(image_not_supported).
  ///
  /// The following sample uses [errorBuilder] to show a '😢' in place of the
  /// image that fails to load, and prints the error to the console.
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return DecoratedBox(
  ///     decoration: BoxDecoration(
  ///       color: Colors.white,
  ///       border: Border.all(),
  ///       borderRadius: BorderRadius.circular(20),
  ///     ),
  ///     child: Image.network(
  ///       'https://example.does.not.exist/image.jpg',
  ///       errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
  ///         // Appropriate logging or analytics, e.g.
  ///         // myAnalytics.recordError(
  ///         //   'An error occurred loading "https://example.does.not.exist/image.jpg"',
  ///         //   exception,
  ///         //   stackTrace,
  ///         // );
  ///         return const Text('😢');
  ///       },
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// `From flutter documentation`
  ///
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  /// A builder function responsible for creating the widget that represents
  /// this image.
  ///
  /// The following sample demonstrates how to use this builder to implement an
  /// image that fades in once it's been loaded.
  ///
  /// This sample contains a limited subset of the functionality that the
  /// [FadeInImage] widget provides out of the box.
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return DecoratedBox(
  ///     decoration: BoxDecoration(
  ///       color: Colors.white,
  ///       border: Border.all(),
  ///       borderRadius: BorderRadius.circular(20),
  ///     ),
  ///     child: Image.network(
  ///       'https://flutter.github.io/assets-for-api-docs/assets/widgets/puffin.jpg',
  ///       frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
  ///         if (wasSynchronouslyLoaded) {
  ///           return child;
  ///         }
  ///         return AnimatedOpacity(
  ///           child: child,
  ///           opacity: frame == null ? 0 : 1,
  ///           duration: const Duration(seconds: 1),
  ///           curve: Curves.easeOut,
  ///         );
  ///       },
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// `From flutter documentation`
  ///
  final Widget Function(BuildContext, Widget, int?, bool)? frameBuilder;

  /// Widget that will help to "query" artwork for song/album.
  ///
  /// A simple example on how you can use the [queryArtwork].
  ///
  /// See more: [QueryArtworkWidget](https://pub.dev/documentation/on_audio_query/latest/on_audio_query/QueryArtworkWidget-class.html)
  const QueryArtworkWidget({
    Key? key,
    required this.id,
    required this.type,
    this.format, // Deprecated
    this.formatType = ArtworkFormatType.JPEG,
    this.size = 200,
    this.quality = 50,
    this.artworkQuality = FilterQuality.low,
    this.artworkBorder,
    this.artworkWidth = 50,
    this.artworkHeight = 50,
    this.artworkFit = BoxFit.cover,
    this.artworkClipBehavior = Clip.antiAlias,
    this.artworkScale = 1.0,
    this.artworkRepeat = ImageRepeat.noRepeat,
    this.artworkColor,
    this.artworkBlendMode,
    this.keepOldArtwork = false,
    this.cacheArtwork = true,
    this.cacheTemporarily = true,
    this.overrideCache = false,
    this.nullArtworkWidget,
    this.errorBuilder,
    this.frameBuilder,
  }) : super(key: key);

  OnAudioQuery get _audioQuery => OnAudioQuery();

  Widget Function(dynamic, dynamic, dynamic) _handleImageError() {
    return (context, exception, stackTrace) {
      return nullArtworkWidget ??
          const Icon(Icons.image_not_supported, size: 50);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (quality != null && quality! > 100) {
      throw Exception(
        '[quality] value cannot be greater than [100]',
      );
    }
    return FutureBuilder<ArtworkModel?>(
      future: _audioQuery.queryArtwork(
        id,
        type,
        filter: MediaFilter.forArtwork(
          artworkFormat: formatType,
          artworkSize: size,
          artworkQuality: quality,
          cacheArtwork: cacheArtwork,
          cacheTemporarily: cacheTemporarily,
          overrideCache: overrideCache,
        ),
      ),
      builder: (context, item) {
        // When you try 'query' without asking for [READ] permission the plugin
        // will throw a [PlatformException].
        //
        // This 'no permission' code exception is: 403.
        if (item.hasError) {
          if (item.error is PlatformException) {
            // Return a 'different' image.
            return const Icon(
              Icons.no_encryption_gmailerrorred,
              size: 50,
            );
          } else {
            // Return a 'error' image.
            return const Icon(
              Icons.error_outline,
              size: 50,
            );
          }
        }

        // No artwork was found or the bytes are empty.
        Uint8List? artwork = item.data?.artwork;
        if (item.data == null || artwork == null || artwork.isEmpty) {
          return nullArtworkWidget ??
              const Icon(
                Icons.image_not_supported,
                size: 50,
              );
        }

        // No errors found, the data(image) is valid. Build the image widget.
        return ClipRRect(
          borderRadius: artworkBorder ?? BorderRadius.circular(50),
          clipBehavior: artworkClipBehavior,
          child: Image.memory(
            item.data!.artwork!,
            gaplessPlayback: keepOldArtwork,
            repeat: artworkRepeat,
            scale: artworkScale,
            width: artworkWidth,
            height: artworkHeight,
            fit: artworkFit,
            color: artworkColor,
            colorBlendMode: artworkBlendMode,
            filterQuality: artworkQuality,
            frameBuilder: frameBuilder,
            errorBuilder: errorBuilder ?? _handleImageError(),
          ),
        );
      },
    );
  }
}
