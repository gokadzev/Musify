import 'package:collection/collection.dart';

abstract class BasePagedList<T> extends DelegatingList<T> {
  BasePagedList(super.base);

  Future<BasePagedList<T>?> nextPage();
}
