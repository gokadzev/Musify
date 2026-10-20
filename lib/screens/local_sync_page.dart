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
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/local_sync_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/custom_bar.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/section_header.dart';

/// Devices on the local network: pair with a new one, sync with a paired one.
class LocalSyncPage extends StatefulWidget {
  const LocalSyncPage({super.key});

  @override
  State<LocalSyncPage> createState() => _LocalSyncPageState();
}

class _LocalSyncPageState extends State<LocalSyncPage> {
  final LocalSyncService _service = LocalSyncService.instance;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _service.resetStatus();
      if (localSyncEnabled.value) {
        _service.startDiscovery();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.syncTitle),
        actions: [
          ValueListenableBuilder<LocalSyncState>(
            valueListenable: _service.state,
            builder: (context, state, _) {
              final busy =
                  state.status == LocalSyncStatus.scanning ||
                  state.status == LocalSyncStatus.syncing ||
                  state.status == LocalSyncStatus.waitingForPin;
              return IconButton(
                icon: const Icon(FluentIcons.arrow_clockwise_24_filled),
                tooltip: 'Scan again',
                onPressed: busy || !localSyncEnabled.value
                    ? null
                    : _service.startDiscovery,
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: localSyncEnabled,
        builder: (context, enabled, _) {
          if (!enabled) {
            return _buildDisabled(context);
          }
          return ValueListenableBuilder<LocalSyncState>(
            valueListenable: _service.state,
            builder: (context, state, _) {
              return ListView(
                padding: commonSingleChildScrollViewPadding,
                children: [
                  _buildThisDevice(context),
                  const SizedBox(height: 16),
                  ..._buildBody(context, state),
                  const MiniPlayerBottomSpace(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDisabled(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.phone_desktop_24_regular,
              size: 56,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Local sync is off. Turn it on to make this device visible to '
              'other Musify devices on your network.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(FluentIcons.wifi_1_24_regular),
              label: const Text('Turn on local sync'),
              onPressed: () async {
                final result = await _service.setEnabled(true);
                if (!context.mounted) return;
                showToast(
                  context,
                  result.message,
                  icon: result.success
                      ? null
                      : FluentIcons.error_circle_24_regular,
                );
                if (result.success) {
                  await _service.startDiscovery();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThisDevice(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _service.serverRunning,
      builder: (context, running, _) {
        return CustomBar(
          _service.deviceName,
          running
              ? FluentIcons.plug_connected_24_regular
              : FluentIcons.plug_disconnected_24_regular,
          description: running
              ? 'This device is visible to other Musify devices on the same network.'
              : 'Not visible right now. Local sync could not start.',
          borderRadius: commonCustomBarRadius,
        );
      },
    );
  }

  List<Widget> _buildBody(BuildContext context, LocalSyncState state) {
    switch (state.status) {
      case LocalSyncStatus.scanning:
        return [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Looking for devices on your network...'),
              ],
            ),
          ),
        ];
      case LocalSyncStatus.syncing:
        return [_buildProgress(context, state)];
      case LocalSyncStatus.waitingForPin:
        return [_buildPinInput(context, state)];
      case LocalSyncStatus.success:
        return [_buildSuccess(context, state)];
      case LocalSyncStatus.error:
        return [_buildError(context, state)];
      case LocalSyncStatus.idle:
        return _buildDeviceLists(context, state);
    }
  }

  Widget _buildProgress(BuildContext context, LocalSyncState state) {
    final theme = Theme.of(context);
    final (progress, label) = switch (state.stage) {
      LocalSyncStage.exporting => (0.15, 'Preparing your library...'),
      LocalSyncStage.exchanging => (0.45, 'Sending it to the other device...'),
      LocalSyncStage.merging => (0.75, 'Merging what came back...'),
      LocalSyncStage.finalizing => (0.95, 'Finishing up...'),
      null => (0.05, 'Connecting...'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        children: [
          Text(
            'Syncing with ${state.activeDevice?.name ?? 'device'}',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 16),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPinInput(BuildContext context, LocalSyncState state) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Icon(
            FluentIcons.link_24_regular,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Pair with ${state.activeDevice?.name ?? 'device'}',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(context.l10n!.syncPinInstructions, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _pinController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 8),
              decoration: const InputDecoration(
                labelText: 'PIN',
                counterText: '',
              ),
              onSubmitted: (_) => _submitPin(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  _pinController.clear();
                  _service.cancelPinInput();
                },
                child: Text(context.l10n!.cancel),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _submitPin, child: const Text('Pair')),
            ],
          ),
        ],
      ),
    );
  }

  void _submitPin() {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      showToast(
        context,
        context.l10n!.syncPinInvalid,
        icon: FluentIcons.error_circle_24_regular,
      );
      return;
    }
    _pinController.clear();
    _service.submitPin(pin);
  }

  Widget _buildSuccess(BuildContext context, LocalSyncState state) {
    final theme = Theme.of(context);
    final stats = state.stats ?? const {};
    final rows = <(String, int)>[
      ('Liked songs', stats['likedSongs'] ?? 0),
      ('Playlists', (stats['playlists'] ?? 0) + (stats['likedPlaylists'] ?? 0)),
      ('Custom playlists', stats['customPlaylists'] ?? 0),
      ('Playlist folders', stats['playlistFolders'] ?? 0),
      ('Recently played', stats['recentlyPlayedSongs'] ?? 0),
      ('Radio stations', stats['likedRadioStations'] ?? 0),
      ('Search history', stats['searchHistory'] ?? 0),
      (context.l10n!.syncRecap, stats['wrappedListeningStats'] ?? 0),
    ].where((row) => row.$2 > 0).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Icon(
            FluentIcons.checkmark_circle_24_regular,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Synced with ${state.activeDevice?.name ?? 'device'}',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            Text(context.l10n!.syncUnchanged, textAlign: TextAlign.center)
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(row.$1),
                            Icon(
                              FluentIcons.checkmark_20_regular,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _service.resetStatus,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, LocalSyncState state) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Icon(
            FluentIcons.error_circle_24_regular,
            size: 56,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            state.errorMessage ?? 'Sync failed',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          if (kDebugMode && state.rawError != null) ...[
            const SizedBox(height: 12),
            Text(
              state.rawError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _service.resetStatus,
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _service.startDiscovery,
                child: const Text('Scan again'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeviceLists(BuildContext context, LocalSyncState state) {
    return [
      ValueListenableBuilder<List<PairedSyncDevice>>(
        valueListenable: _service.pairedDevices,
        builder: (context, paired, _) {
          final discovered = state.discoveredDevices;
          final others = discovered
              .where((d) => !paired.any((p) => p.deviceId == d.deviceId))
              .toList();

          if (paired.isEmpty && others.isEmpty) {
            return _buildEmpty(context);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (paired.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Paired devices',
                  icon: FluentIcons.link_24_filled,
                ),
                for (var i = 0; i < paired.length; i++)
                  _buildPairedDevice(
                    context,
                    paired[i],
                    discovered.cast<DiscoveredSyncDevice?>().firstWhere(
                      (d) => d!.deviceId == paired[i].deviceId,
                      orElse: () => null,
                    ),
                    _radiusFor(i, paired.length),
                  ),
              ],
              if (others.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Other devices',
                  icon: FluentIcons.wifi_1_24_filled,
                ),
                for (var i = 0; i < others.length; i++)
                  CustomBar(
                    others[i].name,
                    _iconFor(others[i].name),
                    description: '${others[i].ip} · Tap to pair and sync',
                    borderRadius: _radiusFor(i, others.length),
                    onTap: () => _service.syncWith(others[i]),
                  ),
              ],
              const SizedBox(height: 16),
              CustomBar(
                'Scan again',
                FluentIcons.arrow_clockwise_24_regular,
                borderRadius: paired.isEmpty
                    ? commonCustomBarRadius
                    : commonCustomBarRadiusFirst,
                onTap: _service.startDiscovery,
              ),
              if (paired.isNotEmpty)
                CustomBar(
                  'Forget all devices',
                  FluentIcons.link_dismiss_24_regular,
                  iconColor: Theme.of(context).colorScheme.error,
                  borderRadius: commonCustomBarRadiusLast,
                  onTap: () => _confirmForgetAll(context),
                ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        children: [
          Icon(
            FluentIcons.wifi_off_24_regular,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          const Text(
            'No other Musify device found. Open Settings on the other device, '
            'turn on Local sync there, and make sure both are on the same '
            'Wi-Fi network.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
            label: const Text('Scan again'),
            onPressed: _service.startDiscovery,
          ),
        ],
      ),
    );
  }

  Widget _buildPairedDevice(
    BuildContext context,
    PairedSyncDevice paired,
    DiscoveredSyncDevice? online,
    BorderRadius borderRadius,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomBar(
      paired.name,
      _iconFor(paired.name),
      description: online != null
          ? '${online.ip} · Online. Tap to sync now'
          : 'Offline. Long press to forget this device',
      iconColor: online != null ? colorScheme.primary : null,
      borderRadius: borderRadius,
      onTap: online != null ? () => _service.syncWith(online) : null,
      onLongPress: () => _confirmForget(context, paired),
    );
  }

  IconData _iconFor(String deviceName) {
    final lower = deviceName.toLowerCase();
    if (lower.contains('android') || lower.contains('ios')) {
      return FluentIcons.phone_24_regular;
    }
    return FluentIcons.desktop_24_regular;
  }

  BorderRadius _radiusFor(int index, int length) {
    if (length == 1) return commonCustomBarRadius;
    if (index == 0) return commonCustomBarRadiusFirst;
    if (index == length - 1) return commonCustomBarRadiusLast;
    return BorderRadius.zero;
  }

  void _confirmForget(BuildContext context, PairedSyncDevice device) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        confirmationMessage:
            'Forget ${device.name}? You will need to pair again with a PIN '
            'before syncing with it.',
        submitMessage: 'Forget',
        isDangerous: true,
        onCancel: () => Navigator.pop(dialogContext),
        onSubmit: () async {
          Navigator.pop(dialogContext);
          await _service.forgetDevice(device.deviceId);
        },
      ),
    );
  }

  void _confirmForgetAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        confirmationMessage:
            'Forget every paired device? Each one will ask for a PIN again.',
        submitMessage: 'Forget all',
        isDangerous: true,
        onCancel: () => Navigator.pop(dialogContext),
        onSubmit: () async {
          Navigator.pop(dialogContext);
          await _service.forgetAllDevices();
        },
      ),
    );
  }
}
