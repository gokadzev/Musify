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
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/platform_utils.dart';

bool get supportsDesktopVolumeControl => isDesktopPlatform;

class DesktopVolumeControl extends StatelessWidget {
  const DesktopVolumeControl({super.key});

  @override
  Widget build(BuildContext context) {
    if (!supportsDesktopVolumeControl) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return StreamBuilder<double>(
      stream: audioHandler.volumeStream,
      initialData: audioHandler.volume,
      builder: (context, snapshot) {
        final volume = (snapshot.data ?? 1.0).clamp(0.0, 1.0);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _iconForVolume(volume),
                color: colors.onSurfaceVariant,
              ),
              iconSize: 22,
              tooltip: context.l10n!.volume,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: colors.onSurfaceVariant,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: audioHandler.toggleMute,
            ),
            SizedBox(
              width: 96,
              height: 32,
              child: _buildSlider(context, volume),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlider(BuildContext context, double volume) {
    final colors = Theme.of(context).colorScheme;
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: colors.onSurfaceVariant,
        inactiveTrackColor: colors.surfaceContainerHighest,
        thumbColor: colors.onSurfaceVariant,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Slider(
        value: volume,
        semanticFormatterCallback: (value) => '${(value * 100).round()}%',
        onChanged: audioHandler.setVolume,
      ),
    );
    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        final delta = event.scrollDelta.dy != 0
            ? event.scrollDelta.dy
            : event.scrollDelta.dx;
        if (delta == 0) return;
        GestureBinding.instance.pointerSignalResolver.register(event, (_) {
          audioHandler.setVolume(
            (audioHandler.volume - delta / 400).clamp(0.0, 1.0),
          );
        });
      },
      child: slider,
    );
  }

  IconData _iconForVolume(double volume) {
    if (volume <= 0.0) return FluentIcons.speaker_mute_24_regular;
    if (volume < 0.5) return FluentIcons.speaker_1_24_regular;
    return FluentIcons.speaker_2_24_regular;
  }
}
