/*
 *     Copyright (C) 2024 Valeri Gokadze
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
