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

import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync_service.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/custom_bar.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/section_header.dart';

/// Localized labels for the sync categories.
Map<SyncCategory, String> syncCategoryLabels(AppLocalizations l10n) => {
  SyncCategory.favourites: l10n.syncFavourites,
  SyncCategory.playlists: l10n.syncPlaylists,
  SyncCategory.recent: l10n.syncRecent,
  SyncCategory.recap: l10n.syncRecap,
  SyncCategory.searches: l10n.syncSearches,
  SyncCategory.radio: l10n.syncRadio,
};

/// Shows the PIN another device must type; listens to [LocalSyncService.incomingPairingRequest].
void showIncomingPairingDialog() {
  final request = LocalSyncService.instance.incomingPairingRequest.value;
  if (request == null) return;

  final context = NavigationManager().context;
  BuildContext? openDialog;

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        openDialog = dialogContext;
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(
            FluentIcons.phone_desktop_24_regular,
            color: colorScheme.primary,
            size: 32,
          ),
          title: Text(dialogContext.l10n!.syncPairTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${request.clientName}\n${dialogContext.l10n!.syncPairDescription}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                request.pin,
                style: Theme.of(dialogContext).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                LocalSyncService.instance.rejectIncomingPairing();
                Navigator.pop(dialogContext);
              },
              child: Text(dialogContext.l10n!.cancel),
            ),
          ],
        );
      },
    ).then((_) => openDialog = null),
  );

  unawaited(
    request.completed.then((paired) {
      final dialog = openDialog;
      openDialog = null;
      if (dialog != null && dialog.mounted) Navigator.of(dialog).pop();
      if (paired && context.mounted) {
        showToast(context, context.l10n!.syncPairedWith(request.clientName));
      }
    }),
  );
}

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
      if (localSyncEnabled.value) _service.startDiscovery();
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
                tooltip: context.l10n!.syncScanAgain,
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
          if (!enabled) return _buildDisabled(context);
          return ValueListenableBuilder<LocalSyncState>(
            valueListenable: _service.state,
            builder: (context, state, _) {
              return ListView(
                padding: commonSingleChildScrollViewPadding,
                children: [
                  _buildThisDevice(context),
                  const SizedBox(height: 16),
                  _buildBody(context, state),
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
            Text(context.l10n!.syncIsOff, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(FluentIcons.wifi_1_24_regular),
              label: Text(context.l10n!.syncTurnOn),
              onPressed: () async {
                if (await _service.setEnabled(true)) {
                  await _service.startDiscovery();
                } else if (context.mounted) {
                  showToast(
                    context,
                    context.l10n!.syncCouldNotStart,
                    icon: FluentIcons.error_circle_24_regular,
                  );
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
              ? context.l10n!.syncVisible
              : context.l10n!.syncNotVisible,
          borderRadius: commonCustomBarRadius,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LocalSyncState state) {
    return switch (state.status) {
      LocalSyncStatus.scanning => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n!.syncScanning),
          ],
        ),
      ),
      LocalSyncStatus.syncing => _buildProgress(context, state),
      LocalSyncStatus.waitingForPin => _buildPinInput(context, state),
      LocalSyncStatus.success => _buildSuccess(context, state),
      LocalSyncStatus.error => _buildError(context, state),
      LocalSyncStatus.idle => _buildDeviceLists(context, state),
    };
  }

  String _activeName(LocalSyncState state) =>
      state.activeDevice?.name ?? 'Musify';

  Widget _buildProgress(BuildContext context, LocalSyncState state) {
    final l10n = context.l10n!;
    final (progress, label) = switch (state.stage) {
      LocalSyncStage.exporting => (0.2, l10n.syncPreparing),
      LocalSyncStage.exchanging => (0.5, l10n.syncSending),
      LocalSyncStage.merging => (0.85, l10n.syncMerging),
      null => (0.05, l10n.syncConnecting),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        children: [
          Text(
            l10n.syncSyncingWith(_activeName(state)),
            style: Theme.of(context).textTheme.titleMedium,
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
    final l10n = context.l10n!;
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
            l10n.syncPairWith(_activeName(state)),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(l10n.syncPinInstructions, textAlign: TextAlign.center),
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
              decoration: InputDecoration(
                labelText: l10n.syncPin,
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
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _submitPin, child: Text(l10n.syncPair)),
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
    final l10n = context.l10n!;
    final stats = state.stats ?? const {};
    final labels = syncCategoryLabels(l10n);
    final changed = [
      for (final category in SyncCategory.values)
        if (syncCategoryKeys[category]!.any((key) => (stats[key] ?? 0) > 0))
          labels[category]!,
    ];

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
            l10n.syncSyncedWith(_activeName(state)),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (changed.isEmpty)
            Text(l10n.syncUnchanged, textAlign: TextAlign.center)
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final label in changed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label),
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
            child: Text(l10n.syncDone),
          ),
        ],
      ),
    );
  }

  String _errorMessage(AppLocalizations l10n, LocalSyncState state) {
    final name = _activeName(state);
    return switch (state.error ?? LocalSyncError.failed) {
      LocalSyncError.notRunning => l10n.syncErrorNotRunning,
      LocalSyncError.incorrectPin => l10n.syncErrorIncorrectPin(name),
      LocalSyncError.rejected => l10n.syncErrorRejected(name),
      LocalSyncError.busy => l10n.syncErrorBusy(name),
      LocalSyncError.untrusted => l10n.syncErrorUntrusted(name),
      LocalSyncError.updateRequired => l10n.syncErrorUpdate,
      LocalSyncError.noCommonCategories => l10n.syncErrorNoCategories,
      LocalSyncError.tooLarge => l10n.syncErrorTooLarge,
      LocalSyncError.unreachable => l10n.syncErrorUnreachable(name),
      LocalSyncError.failed => l10n.syncErrorFailed(name),
    };
  }

  Widget _buildError(BuildContext context, LocalSyncState state) {
    final theme = Theme.of(context);
    final l10n = context.l10n!;
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
            _errorMessage(l10n, state),
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
                child: Text(l10n.back),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _service.startDiscovery,
                child: Text(l10n.syncScanAgain),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceLists(BuildContext context, LocalSyncState state) {
    final l10n = context.l10n!;
    return ValueListenableBuilder<List<PairedSyncDevice>>(
      valueListenable: _service.pairedDevices,
      builder: (context, paired, _) {
        final discovered = {
          for (final device in state.discoveredDevices) device.deviceId: device,
        };
        final pairedIds = paired.map((p) => p.deviceId).toSet();
        final others = discovered.values
            .where((d) => !pairedIds.contains(d.deviceId))
            .toList();

        if (paired.isEmpty && others.isEmpty) return _buildEmpty(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (paired.isNotEmpty) ...[
              SectionHeader(
                title: l10n.syncPairedDevices,
                icon: FluentIcons.link_24_filled,
              ),
              for (var i = 0; i < paired.length; i++)
                _buildPairedDevice(
                  context,
                  paired[i],
                  discovered[paired[i].deviceId],
                  _radiusFor(i, paired.length),
                ),
            ],
            if (others.isNotEmpty) ...[
              SectionHeader(
                title: l10n.syncOtherDevices,
                icon: FluentIcons.wifi_1_24_filled,
              ),
              for (var i = 0; i < others.length; i++)
                CustomBar(
                  others[i].name,
                  _iconFor(others[i].name),
                  description: l10n.syncTapToPair(others[i].ip),
                  borderRadius: _radiusFor(i, others.length),
                  onTap: () => _service.syncWith(others[i]),
                ),
            ],
            const SizedBox(height: 16),
            CustomBar(
              l10n.syncScanAgain,
              FluentIcons.arrow_clockwise_24_regular,
              borderRadius: paired.isEmpty
                  ? commonCustomBarRadius
                  : commonCustomBarRadiusFirst,
              onTap: _service.startDiscovery,
            ),
            if (paired.isNotEmpty)
              CustomBar(
                l10n.syncForgetAll,
                FluentIcons.link_dismiss_24_regular,
                iconColor: Theme.of(context).colorScheme.error,
                borderRadius: commonCustomBarRadiusLast,
                onTap: () => _confirmForget(context, null),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        children: [
          Icon(
            FluentIcons.wifi_off_24_regular,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(context.l10n!.syncNoDevices, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
            label: Text(context.l10n!.syncScanAgain),
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
    return CustomBar(
      paired.name,
      _iconFor(paired.name),
      description: online != null
          ? context.l10n!.syncTapToSync(online.ip)
          : context.l10n!.syncOfflineDevice,
      iconColor: online != null ? Theme.of(context).colorScheme.primary : null,
      borderRadius: borderRadius,
      onTap: online != null ? () => _service.syncWith(online) : null,
      onLongPress: () => _confirmForget(context, paired),
    );
  }

  IconData _iconFor(String deviceName) =>
      deviceName.toLowerCase().contains('android')
      ? FluentIcons.phone_24_regular
      : FluentIcons.desktop_24_regular;

  BorderRadius _radiusFor(int index, int length) {
    if (length == 1) return commonCustomBarRadius;
    if (index == 0) return commonCustomBarRadiusFirst;
    if (index == length - 1) return commonCustomBarRadiusLast;
    return BorderRadius.zero;
  }

  /// Forgets [device], or every paired device when it is null.
  void _confirmForget(BuildContext context, PairedSyncDevice? device) {
    final l10n = context.l10n!;
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        confirmationMessage: device == null
            ? l10n.syncForgetAllConfirm
            : l10n.syncForgetConfirm(device.name),
        submitMessage: device == null ? l10n.syncForgetAll : l10n.syncForget,
        isDangerous: true,
        onCancel: () => Navigator.pop(dialogContext),
        onSubmit: () async {
          Navigator.pop(dialogContext);
          if (device == null) {
            await _service.forgetAllDevices();
          } else {
            await _service.forgetDevice(device.deviceId);
          }
        },
      ),
    );
  }
}
