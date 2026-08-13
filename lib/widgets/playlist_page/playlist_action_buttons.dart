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
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';

/// Play and shuffle whatever the page is about, shared by the playlist and the
/// artist pages. While [isLoading] the songs are still being read, so both
/// buttons wait instead of playing an incomplete list.
class PlaylistActionButtons extends StatelessWidget {
  const PlaylistActionButtons({
    super.key,
    required this.onPlay,
    required this.onShuffle,
    this.isLoading = false,
  });

  final VoidCallback onPlay;

  final AsyncCallback onShuffle;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              icon: isLoading
                  ? const _Spinner()
                  : const Icon(FluentIcons.play_24_filled),
              label: Text(context.l10n!.play),
              onPressed: isLoading ? null : onPlay,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
              icon: isLoading
                  ? const _Spinner()
                  : const Icon(FluentIcons.arrow_shuffle_24_filled),
              label: Text(context.l10n!.shuffle),
              onPressed: isLoading ? null : onShuffle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Replaces the icon of a button while its songs are being read.
class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
