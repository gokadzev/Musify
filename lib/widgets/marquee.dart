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

class MarqueeWidget extends StatefulWidget {
  const MarqueeWidget({
    super.key,
    required this.child,
    this.direction = Axis.horizontal,
    this.animationDuration = const Duration(milliseconds: 6000),
    this.backDuration = const Duration(milliseconds: 800),
    this.pauseDuration = const Duration(milliseconds: 800),
    this.manualScrollEnabled = true,
  });

  final Widget child;
  final Axis direction;
  final Duration animationDuration, backDuration, pauseDuration;
  final bool manualScrollEnabled;

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  bool _isAnimating = false;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimation());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: widget.direction,
        controller: _scrollController,
        physics: widget.manualScrollEnabled
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: widget.child,
      ),
    );
  }

  Future<void> _startAnimation() async {
    if (_isDisposed || _isAnimating) return;

    _isAnimating = true;

    while (_scrollController.hasClients && !_isDisposed) {
      try {
        // Check if content actually needs scrolling
        if (_scrollController.position.maxScrollExtent <= 0) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        await Future.delayed(widget.pauseDuration);
        if (_isDisposed || !_scrollController.hasClients) break;

        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: widget.animationDuration,
          curve: Curves.linear,
        );

        await Future.delayed(widget.pauseDuration);
        if (_isDisposed || !_scrollController.hasClients) break;

        await _scrollController.animateTo(
          0,
          duration: widget.backDuration,
          curve: Curves.easeOut,
        );
      } catch (e) {
        // Handle animation interruptions gracefully
        break;
      }
    }

    _isAnimating = false;
  }
}
