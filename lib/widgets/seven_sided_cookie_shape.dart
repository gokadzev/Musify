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

class SevenSidedCookieShape extends StatelessWidget {
  const SevenSidedCookieShape({
    required this.size,
    required this.color,
    required this.child,
    super.key,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CustomShape7Painter(color),
        child: Center(child: child),
      ),
    );
  }
}

class _CustomShape7Painter extends CustomPainter {
  const _CustomShape7Painter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centeredPath = _buildShape7Path(size)
        .shift(Offset(-size.width * 0.075, -size.height * 0.07));
    canvas.drawPath(centeredPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CustomShape7Painter oldDelegate) =>
      oldDelegate.color != color;
}

Path _buildShape7Path(Size size) {
  final path = Path()
    ..moveTo(size.width * 0.43, size.height * 0.13)
    ..cubicTo(
      size.width * 0.51,
      size.height * 0.05,
      size.width * 0.64,
      size.height * 0.05,
      size.width * 0.73,
      size.height * 0.13,
    )
    ..cubicTo(
      size.width * 0.76,
      size.height * 0.16,
      size.width * 0.8,
      size.height * 0.17,
      size.width * 0.83,
      size.height * 0.18,
    )
    ..cubicTo(
      size.width * 0.95,
      size.height / 5,
      size.width * 1.03,
      size.height * 0.3,
      size.width * 1.02,
      size.height * 0.42,
    )
    ..cubicTo(
      size.width * 1.03,
      size.height / 2,
      size.width * 1.05,
      size.height * 0.54,
      size.width * 1.05,
      size.height * 0.54,
    )
    ..cubicTo(
      size.width * 1.1,
      size.height * 0.64,
      size.width * 1.08,
      size.height * 0.77,
      size.width,
      size.height * 0.83,
    )
    ..cubicTo(
      size.width * 0.98,
      size.height * 0.84,
      size.width * 0.95,
      size.height * 0.86,
      size.width * 0.91,
      size.height * 0.93,
    )
    ..cubicTo(
      size.width * 0.86,
      size.height * 1.04,
      size.width * 0.75,
      size.height * 1.09,
      size.width * 0.64,
      size.height * 1.06,
    )
    ..cubicTo(
      size.width * 0.6,
      size.height * 1.05,
      size.width * 0.56,
      size.height * 1.05,
      size.width * 0.52,
      size.height * 1.06,
    )
    ..cubicTo(
      size.width * 0.41,
      size.height * 1.09,
      size.width * 0.29,
      size.height * 1.04,
      size.width / 4,
      size.height * 0.93,
    )
    ..cubicTo(
      size.width / 5,
      size.height * 0.86,
      size.width * 0.17,
      size.height * 0.84,
      size.width * 0.17,
      size.height * 0.83,
    )
    ..cubicTo(
      size.width * 0.08,
      size.height * 0.77,
      size.width * 0.05,
      size.height * 0.64,
      size.width * 0.1,
      size.height * 0.54,
    )
    ..cubicTo(
      size.width * 0.12,
      size.height / 2,
      size.width * 0.13,
      size.height * 0.46,
      size.width * 0.13,
      size.height * 0.42,
    )
    ..cubicTo(
      size.width * 0.13,
      size.height * 0.3,
      size.width / 5,
      size.height / 5,
      size.width * 0.32,
      size.height * 0.18,
    )
    ..cubicTo(
      size.width * 0.36,
      size.height * 0.17,
      size.width * 0.4,
      size.height * 0.16,
      size.width * 0.42,
      size.height * 0.13,
    )
    ..close();
  return path;
}
