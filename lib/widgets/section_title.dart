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
import 'package:musify/widgets/marque.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, this.primaryColor, {super.key, this.icon});
  final Color primaryColor;
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: MarqueeWidget(
              child: Text(
                title,
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontSize:
                      Theme.of(context).textTheme.titleMedium?.fontSize ?? 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
