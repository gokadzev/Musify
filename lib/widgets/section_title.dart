import 'package:flutter/material.dart';
import 'package:musify/widgets/marque.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title,
    this.primaryColor, {
    this.fontSize = 15,
    super.key,
  });
  final Color primaryColor;
  final String title;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.7,
          child: MarqueeWidget(
            child: Text(
              title,
              style: TextStyle(
                color: primaryColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
