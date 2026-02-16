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
import 'package:just_audio/just_audio.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/common_variables.dart';

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

  @override
  void initState() {
    super.initState();
    _loadEqualizer();
  }

  Future<void> _loadEqualizer() async {
    if (!audioHandler.isEqualizerSupported) {
      setState(() => _isLoading = false);
      return;
    }

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
      logger.log('Failed to load equalizer page', e, stackTrace);
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
      appBar: AppBar(title: Text(context.l10n!.equalizer)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !audioHandler.isEqualizerSupported
          ? Center(
              child: Padding(
                padding: commonSingleChildScrollViewPadding,
                child: Text(
                  context.l10n!.equalizerAndroidOnly,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            )
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
                Card.outlined(
                  child: SwitchListTile.adaptive(
                    title: Text(context.l10n!.equalizerEnable),
                    subtitle: Text(
                      _enabled
                          ? context.l10n!.equalizerEnabledHint
                          : context.l10n!.equalizerDisabledHint,
                    ),
                    value: _enabled,
                    onChanged: (value) async {
                      await audioHandler.setEqualizerEnabled(value);
                      if (!mounted) return;
                      setState(() => _enabled = value);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await audioHandler.resetEqualizerBands();
                    final params = _params;
                    if (!mounted || params == null) return;
                    setState(() {
                      _gains = List<double>.filled(params.bands.length, 0);
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n!.equalizerResetBands),
                ),
                const SizedBox(height: 12),
                ...List.generate(_params!.bands.length, (index) {
                  final band = _params!.bands[index];
                  final gain = _gains[index];
                  final min = _params!.minDecibels;
                  final max = _params!.maxDecibels;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatFrequency(band.centerFrequency),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  '${gain.toStringAsFixed(1)} dB',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Slider(
                              value: gain.clamp(min, max),
                              min: min,
                              max: max,
                              divisions: ((max - min) * 2).round(),
                              label: '${gain.toStringAsFixed(1)} dB',
                              onChanged: (value) {
                                setState(() {
                                  _gains[index] = value;
                                });
                              },
                              onChangeEnd: (value) async {
                                await audioHandler.setEqualizerBandGain(
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
              ],
            ),
    );
  }
}
