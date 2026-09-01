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

import 'package:material_ui/material_ui.dart';

class EightLeafClover extends StatelessWidget {
  const EightLeafClover({
    required this.size,
    required this.color,
    required this.child,
    this.onTap,
    super.key,
  });

  final double size;
  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _EightLeafCloverPainter(color),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _EightLeafCloverPainter extends CustomPainter {
  const _EightLeafCloverPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_buildEightLeafCloverPath(size), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _EightLeafCloverPainter oldDelegate) =>
      oldDelegate.color != color;
}

Path _buildEightLeafCloverPath(Size size) {
  final path = Path()
    ..moveTo(size.width * 0.61, 0)
    ..cubicTo(
      size.width * 0.71,
      0,
      size.width * 0.8,
      size.height * 0.07,
      size.width * 0.83,
      size.height * 0.16,
    )
    ..cubicTo(
      size.width * 0.93,
      size.height * 0.18,
      size.width,
      size.height * 0.27,
      size.width,
      size.height * 0.38,
    )
    ..cubicTo(
      size.width,
      size.height * 0.42,
      size.width,
      size.height * 0.47,
      size.width * 0.96,
      size.height / 2,
    )
    ..cubicTo(
      size.width,
      size.height * 0.54,
      size.width,
      size.height * 0.58,
      size.width,
      size.height * 0.62,
    )
    ..cubicTo(
      size.width,
      size.height * 0.73,
      size.width * 0.93,
      size.height * 0.82,
      size.width * 0.83,
      size.height * 0.84,
    )
    ..cubicTo(
      size.width * 0.8,
      size.height * 0.93,
      size.width * 0.71,
      size.height,
      size.width * 0.61,
      size.height,
    )
    ..cubicTo(
      size.width * 0.57,
      size.height,
      size.width * 0.53,
      size.height,
      size.width / 2,
      size.height * 0.98,
    )
    ..cubicTo(
      size.width * 0.47,
      size.height,
      size.width * 0.43,
      size.height,
      size.width * 0.39,
      size.height,
    )
    ..cubicTo(
      size.width * 0.29,
      size.height,
      size.width / 5,
      size.height * 0.93,
      size.width * 0.17,
      size.height * 0.84,
    )
    ..cubicTo(
      size.width * 0.07,
      size.height * 0.82,
      0,
      size.height * 0.73,
      0,
      size.height * 0.62,
    )
    ..cubicTo(
      0,
      size.height * 0.58,
      size.width * 0.01,
      size.height * 0.54,
      size.width * 0.04,
      size.height / 2,
    )
    ..cubicTo(
      size.width * 0.01,
      size.height * 0.47,
      0,
      size.height * 0.42,
      0,
      size.height * 0.38,
    )
    ..cubicTo(
      0,
      size.height * 0.27,
      size.width * 0.07,
      size.height * 0.18,
      size.width * 0.17,
      size.height * 0.16,
    )
    ..cubicTo(
      size.width / 5,
      size.height * 0.07,
      size.width * 0.29,
      0,
      size.width * 0.39,
      0,
    )
    ..cubicTo(
      size.width * 0.43,
      0,
      size.width * 0.47,
      size.height * 0.01,
      size.width / 2,
      size.height * 0.02,
    )
    ..cubicTo(
      size.width * 0.53,
      size.height * 0.01,
      size.width * 0.57,
      0,
      size.width * 0.61,
      0,
    )
    ..close();
  return path;
}
