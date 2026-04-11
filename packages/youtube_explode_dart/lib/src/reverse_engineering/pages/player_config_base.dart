import '../../extensions/helpers_extension.dart';

/// Base class for PlayerConfig.
abstract class PlayerConfigBase {
  /// Root node.
  final JsonMap root;

  ///
  PlayerConfigBase(this.root);

  /// Player source url.
  String get sourceUrl;
}
