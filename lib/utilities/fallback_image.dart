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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FallbackNetworkImage extends StatefulWidget {
  const FallbackNetworkImage({
    super.key,
    required this.imageUrl,
    this.fallbackUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.imageBuilder,
    this.placeholder,
    required this.errorChild,
  });

  final String imageUrl;

  final String? fallbackUrl;

  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;

  final ImageWidgetBuilder? imageBuilder;

  final PlaceholderWidgetBuilder? placeholder;

  final Widget errorChild;

  static final Set<String> _failedUrls = {};

  @override
  State<FallbackNetworkImage> createState() => _FallbackNetworkImageState();
}

class _FallbackNetworkImageState extends State<FallbackNetworkImage> {
  late String _url;

  @override
  void initState() {
    super.initState();
    _url = _pickUrl(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant FallbackNetworkImage old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl ||
        old.fallbackUrl != widget.fallbackUrl) {
      final next = _pickUrl(widget.imageUrl);
      if (next != _url) setState(() => _url = next);
    }
  }

  String _pickUrl(String primary) {
    if (!FallbackNetworkImage._failedUrls.contains(primary)) return primary;
    final fb = widget.fallbackUrl;
    if (fb != null &&
        fb.isNotEmpty &&
        !FallbackNetworkImage._failedUrls.contains(fb)) {
      return fb;
    }
    return primary;
  }

  void _onLoadError(String failedUrl) {
    FallbackNetworkImage._failedUrls.add(failedUrl);

    final fb = widget.fallbackUrl;
    if (_url == widget.imageUrl &&
        fb != null &&
        fb.isNotEmpty &&
        fb != widget.imageUrl &&
        !FallbackNetworkImage._failedUrls.contains(fb)) {
      // setState must not be called directly inside a build callback, so we
      // defer to the post-frame phase.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _url = fb);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      key: ValueKey(_url),
      imageUrl: _url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      imageBuilder: widget.imageBuilder,
      placeholder: widget.placeholder,
      errorWidget: (ctx, url, err) {
        _onLoadError(url);
        return widget.errorChild;
      },
    );
  }
}
