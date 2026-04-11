import 'package:meta/meta.dart';

import '../../extensions/helpers_extension.dart';

@internal
abstract class InitialData {
  final JsonMap root;

  InitialData(this.root);
}
