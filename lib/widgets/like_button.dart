import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class LikeButton extends StatelessWidget {
  LikeButton({
    super.key,
    required this.onSecondaryColor,
    required this.onPrimaryColor,
    required this.isLiked,
    required this.onPressed,
  });
  final Color onSecondaryColor;
  final Color onPrimaryColor;
  final bool isLiked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const likeStatusToIconMapper = {
      true: FluentIcons.heart_24_filled,
      false: FluentIcons.heart_24_regular,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onSecondaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          likeStatusToIconMapper[isLiked],
          color: onPrimaryColor,
          size: 25,
        ),
      ),
    );
  }
}
