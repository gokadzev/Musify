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

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum RotateSide { right, left, top, bottom }

class FlipCardController {
  _FlipCardState? _state;

  Future<void> flipcard() async {
    await _state?.flipCard();
  }
}

class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.frontWidget,
    required this.backWidget,
    required this.controller,
    required this.rotateSide,
    this.onTapFlipping = false,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  final Widget frontWidget;
  final Widget backWidget;
  final FlipCardController controller;
  final bool onTapFlipping;
  final RotateSide rotateSide;
  final Duration animationDuration;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  double _startAngle = 0;
  double _targetAngle = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller._state == this) {
        oldWidget.controller._state = null;
      }
      widget.controller._state = this;
    }
    if (oldWidget.animationDuration != widget.animationDuration) {
      _animationController.duration = widget.animationDuration;
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) {
      widget.controller._state = null;
    }
    _animationController.dispose();
    super.dispose();
  }

  Future<void> flipCard() async {
    if (_animationController.isAnimating) return;
    _startAngle = _targetAngle;
    _targetAngle = _targetAngle == 0 ? math.pi : 0;
    await _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final progress = _animationController.value;
        final angle = _startAngle + (_targetAngle - _startAngle) * progress;
        final isFrontVisible = angle <= math.pi / 2;
        final rotateX =
            widget.rotateSide == RotateSide.top ||
            widget.rotateSide == RotateSide.bottom;
        final direction =
            widget.rotateSide == RotateSide.left ||
                widget.rotateSide == RotateSide.top
            ? 1
            : -1;
        final transform = Matrix4.identity()..setEntry(3, 2, 0.001);
        if (rotateX) {
          transform.rotateX(angle * direction);
        } else {
          transform.rotateY(angle * direction);
        }

        return GestureDetector(
          onTap: widget.onTapFlipping ? flipCard : null,
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            child: isFrontVisible
                ? widget.frontWidget
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateX(rotateX ? math.pi : 0)
                      ..rotateY(rotateX ? 0 : math.pi),
                    child: widget.backWidget,
                  ),
          ),
        );
      },
    );
  }
}
