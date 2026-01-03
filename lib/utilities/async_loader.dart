/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/widgets/spinner.dart';

Widget _defaultAsyncLoaderErrorBuilder(
  BuildContext context,
  Object? error,
  StackTrace? stack,
) {
  return Center(child: Text('${context.l10n!.error}!'));
}

/// A small helper that reduces boilerplate around common FutureBuilder
/// usage: shows a spinner while waiting, a standardized error widget on
/// error, and calls [builder] when data is available. If [emptyWidget]
/// is provided and the data is an empty [Iterable] or `null`, it will be
/// shown instead of calling [builder].
class AsyncLoader<T> extends StatelessWidget {
  const AsyncLoader({
    super.key,
    required this.future,
    required this.builder,
    this.emptyWidget = const SizedBox.shrink(),
    this.loadingWidget = const Center(child: Spinner()),
    this.errorBuilder = _defaultAsyncLoaderErrorBuilder,
  });

  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final Widget emptyWidget;
  final Widget loadingWidget;
  final Widget Function(BuildContext, Object?, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget;
        }

        if (snapshot.hasError) {
          logger.log('AsyncLoader error', snapshot.error, snapshot.stackTrace);
          return errorBuilder!(context, snapshot.error, snapshot.stackTrace);
        }

        final data = snapshot.data;
        if (data == null) return emptyWidget;

        if (data is Iterable && data.isEmpty) {
          return emptyWidget;
        }

        return builder(context, data);
      },
    );
  }
}
