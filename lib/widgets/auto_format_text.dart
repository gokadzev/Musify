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

class AutoFormatText extends StatelessWidget {
  AutoFormatText({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];

    final boldExp = RegExp(r'\*\*(.*?)\*\*');
    final matches = boldExp.allMatches(text);
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    var currentTextIndex = 0;

    for (final match in matches) {
      spans
        ..add(
          TextSpan(
            text: text
                .substring(currentTextIndex, match.start)
                .replaceAll('* ', '• '),
            style: textStyle,
          ),
        )
        ..add(
          TextSpan(
            text: match.group(1),
            style: textStyle?.copyWith(fontWeight: FontWeight.bold),
          ),
        );

      currentTextIndex = match.end;
    }

    spans.add(
      TextSpan(
        text: text.substring(currentTextIndex).replaceAll('* ', '• '),
        style: textStyle,
      ),
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }
}
