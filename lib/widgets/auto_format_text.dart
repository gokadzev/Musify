import 'package:flutter/material.dart';

class AutoFormatText extends StatelessWidget {
  AutoFormatText({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];

    final exp = RegExp(r'\*\*(.*?)\*\*');
    final matches = exp.allMatches(text);

    var currentTextIndex = 0;

    for (final match in matches) {
      spans.add(
        TextSpan(
          text: text.substring(currentTextIndex, match.start),
          style: const TextStyle(fontSize: 16),
        ),
      );

      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );

      currentTextIndex = match.end;
    }

    spans.add(
      TextSpan(
        text: text.substring(currentTextIndex),
        style: const TextStyle(fontSize: 16),
      ),
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }
}
