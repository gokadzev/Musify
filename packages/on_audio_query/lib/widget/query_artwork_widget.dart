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

part of on_audio_query;

/// Widget that will help to "query" artwork for song/album.
///
/// A simple example on how you can use the [queryArtwork].
///
/// Important:
///
/// * If [controller] is null, will be create a new instance.
/// * Log set with [setLogConfig] will only work if [controller] is not null.
///
/// See more: [QueryArtworkWidget](https://pub.dev/documentation/on_audio_query/latest/on_audio_query/QueryArtworkWidget-class.html)
class QueryArtworkWidget extends StatelessWidget {
  /// Used to find and get image.
  ///
  /// All Audio/Song has a unique [id].
  final int id;

  /// Used to call the platform specific method.
  ///
  /// Important:
  ///
  /// * If [controller] is null, will be create a new instance.
  /// * Log set with [setLogConfig] will only work if [controller] is not null.
  final OnAudioQuery? controller;

  /// Used to define artwork [type].
  ///
  /// Opts: [AUDIO] and [ALBUM].
  final ArtworkType type;

  /// Used to define artwork [format].
  ///
  /// Opts: [JPEG] and [PNG].
  ///
  /// Important:
  ///
  /// * If [format] is not defined, will be set to [JPEG].
  final ArtworkFormat format;

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
  /// * If [quality] is not defined, will be set to [100].
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
  /// * If [artworkQuality] is not defined, will be set to [low].
  /// * This value doesn't have a directly influence to image quality.
  final FilterQuality artworkQuality;

  /// Used to define artwork [width].
  ///
  /// Important:
  ///
  /// * If [artworkWidth] is not defined, will be set to [50].
  final double artworkWidth;

  /// Used to define artwork [height].
  ///
  /// Important:
  ///
  /// * If [artworkHeight] is not defined, will be set to [50].
  final double artworkHeight;

  /// Used to define artwork [fit].
  ///
  /// Important:
  ///
  /// * If [artworkFit] is not defined, will be set to [cover].
  final BoxFit artworkFit;

  /// Used to define artwork [clip].
  ///
  /// Important:
  ///
  /// * If [artworkClipBehavior] is not defined, will be set to [antiAlias].
  final Clip artworkClipBehavior;

  /// Used to define artwork [scale].
  ///
  /// Important:
  ///
  /// * If [artworkScale] is not defined, will be set to [1.0].
  final double artworkScale;

  /// Used to define if artwork should [repeat].
  ///
  /// Important:
  ///
  /// * If [artworkRepeat] is not defined, will be set to [false].
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
  /// * If [keepOldArtwork] is not defined, will be set to [false].
  final bool keepOldArtwork;

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
    this.quality = 50,
    this.controller,
    this.format = ArtworkFormat.JPEG,
    this.size = 200,
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
    this.nullArtworkWidget,
    this.errorBuilder,
    this.frameBuilder,
  })  : assert(quality <= 100),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: (controller ?? OnAudioQuery()).queryArtwork(
        id,
        type,
        format: format,
        size: size,
        quality: quality,
      ),
      builder: (context, item) {
        if (item.data != null && item.data!.isNotEmpty) {
          return ClipRRect(
            borderRadius: artworkBorder ?? BorderRadius.circular(50),
            clipBehavior: artworkClipBehavior,
            child: Image.memory(
              item.data!,
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
              errorBuilder: errorBuilder ??
                  (context, exception, stackTrace) {
                    return nullArtworkWidget ??
                        const Icon(
                          Icons.image_not_supported,
                          size: 50,
                        );
                  },
            ),
          );
        }
        return nullArtworkWidget ??
            const Icon(
              Icons.image_not_supported,
              size: 50,
            );
      },
    );
  }
}
