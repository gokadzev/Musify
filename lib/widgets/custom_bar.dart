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
import 'package:musify/utilities/common_variables.dart';

class CustomBar extends StatelessWidget {
  CustomBar(
    this.tileName,
    this.tileIcon, {
    this.description,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final String tileName;
  final IconData tileIcon;
  final String? description;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: commonBarPadding,
      child: Card(
        margin: const EdgeInsets.only(bottom: 3),
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: onTap,
            onLongPress: onLongPress,
            child: ListTile(
              minTileHeight: 45,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tileIcon, size: 22),
              ),
              title: Text(
                tileName,
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
              subtitle: description != null
                  ? Text(
                      description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            textColor?.withValues(alpha: 0.75) ??
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              trailing: trailing,
            ),
          ),
        ),
      ),
    );
  }
}
