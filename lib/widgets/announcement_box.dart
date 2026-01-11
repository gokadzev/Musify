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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/utilities/url_launcher.dart';

class AnnouncementBox extends StatelessWidget {
  const AnnouncementBox({
    super.key,
    required this.message,
    required this.url,
    this.onDismiss,
  });
  final String message;
  final String url;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => launchURL(Uri.parse(url)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FluentIcons.megaphone_24_filled,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            context.l10n!.tapToView,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            FluentIcons.arrow_right_16_filled,
                            size: 12,
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: Icon(
                      FluentIcons.dismiss_circle_24_regular,
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    onPressed: onDismiss,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
