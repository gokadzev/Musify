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
import 'package:just_audio/just_audio.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/settings_manager.dart';

class EqualizerPage extends StatefulWidget {
  const EqualizerPage({super.key});

  @override
  State<EqualizerPage> createState() => _EqualizerPageState();
}

class _EqualizerPageState extends State<EqualizerPage> {
  AndroidEqualizerParameters? _params;
  List<double> _gains = [];
  bool _enabled = equalizerEnabled.value;
  bool _isLoading = true;
  String? _activePreset;

  // Preset IDs
  static const List<String> _presetIds = [
    'balanced',
    'bassBoost',
    'trebleBoost',
    'vocal',
    'rock',
    'pop',
    'electronic',
  ];

  // Get localized name for a preset
  String _getPresetLocalizedName(BuildContext context, String presetId) {
    switch (presetId) {
      case 'balanced':
        return context.l10n!.equalizerPresetBalanced;
      case 'bassBoost':
        return context.l10n!.equalizerPresetBassBoost;
      case 'trebleBoost':
        return context.l10n!.equalizerPresetTrebleBoost;
      case 'vocal':
        return context.l10n!.equalizerPresetVocal;
      case 'rock':
        return context.l10n!.equalizerPresetRock;
      case 'pop':
        return context.l10n!.equalizerPresetPop;
      case 'electronic':
        return context.l10n!.equalizerPresetElectronic;
      default:
        return presetId;
    }
  }

  // Get preset gains for the current number of bands
  List<double> _getPresetGains(String preset) {
    final bandCount = _params?.bands.length ?? 0;
    if (bandCount == 0) return [];

    // Normalize band index to 0-1 range for frequency distribution
    final normalizedGains = List<double>.generate(bandCount, (i) {
      final position = bandCount > 1 ? i / (bandCount - 1) : 0.0;

      switch (preset) {
        case 'balanced':
          // Neutral, flat response
          return 0.0;

        case 'bassBoost':
          // Strong bass, reduced highs
          if (position < 0.33) return 8.0;
          if (position < 0.66) return 3.0;
          return -2.0;

        case 'trebleBoost':
          // Strong treble, reduced lows
          if (position < 0.33) return -2.0;
          if (position < 0.66) return 2.0;
          return 8.0;

        case 'vocal':
          // Mid-range boost for clear vocals
          if (position < 0.2) return 2.0;
          if (position < 0.5) return 6.0;
          if (position < 0.8) return 4.0;
          return 1.0;

        case 'rock':
          // Powerful bass + presence peak
          if (position < 0.25) return 7.0;
          if (position < 0.5) return 2.0;
          if (position < 0.75) return 4.0;
          return 6.0;

        case 'pop':
          // Balanced with slight mid boost
          if (position < 0.3) return 3.0;
          if (position < 0.6) return 4.0;
          return 2.0;

        case 'electronic':
          // Punchy bass + presence peak
          if (position < 0.2) return 9.0;
          if (position < 0.5) return -1.0;
          if (position < 0.8) return 3.0;
          return 7.0;

        default:
          return 0.0;
      }
    });

    return normalizedGains;
  }

  Future<void> _applyPreset(String preset) async {
    final presetGains = _getPresetGains(preset);
    for (var i = 0; i < presetGains.length; i++) {
      await audioHandler.setEqualizerBandGain(i, presetGains[i]);
    }
    if (!mounted) return;
    setState(() {
      _gains = presetGains;
      _activePreset = preset;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadEqualizer();
  }

  Future<void> _loadEqualizer() async {
    try {
      final params = await audioHandler.getEqualizerParameters();
      if (!mounted) return;

      if (params != null) {
        setState(() {
          _params = params;
          _gains = params.bands.map((band) => band.gain).toList();
          _enabled = equalizerEnabled.value;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      logger.log(
        'Failed to load equalizer page',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatFrequency(double hz) {
    if (hz >= 1000) {
      return hz >= 10000
          ? '${(hz / 1000).toStringAsFixed(0)} kHz'
          : '${(hz / 1000).toStringAsFixed(1)} kHz';
    }
    return '${hz.round()} Hz';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.equalizer),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.arrow_clockwise_24_filled),
            tooltip: context.l10n!.equalizerResetBands,
            onPressed: () async {
              await audioHandler.resetEqualizerBands();
              final params = _params;
              if (!mounted || params == null) return;
              setState(() {
                _gains = List<double>.filled(params.bands.length, 0);
                _activePreset = null;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _params == null
          ? Center(
              child: Padding(
                padding: commonSingleChildScrollViewPadding,
                child: Text(
                  context.l10n!.equalizerInitFailed,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: commonSingleChildScrollViewPadding,
              children: [
                // Enable/Disable Section
                Card.filled(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n!.equalizerEnable,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: colorScheme.onSurface),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _enabled
                                    ? context.l10n!.equalizerEnabledHint
                                    : context.l10n!.equalizerDisabledHint,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _enabled,
                          onChanged: (value) async {
                            await audioHandler.setEqualizerEnabled(value);
                            if (!mounted) return;
                            setState(() => _enabled = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Presets Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n!.equalizerPresets,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presetIds.map((presetId) {
                          final isActive = _activePreset == presetId;
                          return FilledButton(
                            onPressed: () => _applyPreset(presetId),
                            style: FilledButton.styleFrom(
                              backgroundColor: isActive
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              foregroundColor: isActive
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              elevation: isActive ? 2 : 0,
                            ),
                            child: Text(
                              _getPresetLocalizedName(context, presetId),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Bands Section
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.l10n!.equalizerBands,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: List.generate(_params!.bands.length, (
                            index,
                          ) {
                            final band = _params!.bands[index];
                            final gain = _gains[index];
                            final min = _params!.minDecibels;
                            final max = _params!.maxDecibels;
                            final isLast = index == _params!.bands.length - 1;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLast ? 16 : 12,
                              ),
                              child: Card.filled(
                                color: colorScheme.surface,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatFrequency(
                                              band.centerFrequency,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  colorScheme.primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${gain.toStringAsFixed(1)} dB',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onPrimaryContainer,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Slider.adaptive(
                                        value: gain.clamp(min, max),
                                        min: min,
                                        max: max,
                                        divisions: ((max - min) * 2).round(),
                                        label: '${gain.toStringAsFixed(1)} dB',
                                        onChanged: (value) {
                                          setState(() {
                                            _gains[index] = value;
                                            _activePreset = null;
                                          });
                                        },
                                        onChangeEnd: (value) async {
                                          await audioHandler
                                              .setEqualizerBandGain(
                                                index,
                                                value,
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}
