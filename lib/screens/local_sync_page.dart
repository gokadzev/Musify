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
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync_service.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/platform_utils.dart';
import 'package:musify/widgets/bottom_sheet_bar.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/custom_bar.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/section_header.dart';

Map<SyncCategory, String> syncCategoryLabels(AppLocalizations l10n) => {
  SyncCategory.favourites: l10n.syncFavourites,
  SyncCategory.playlists: l10n.syncPlaylists,
  SyncCategory.recent: l10n.syncRecent,
  SyncCategory.recap: l10n.syncRecap,
  SyncCategory.searches: l10n.syncSearches,
  SyncCategory.radio: l10n.syncRadio,
};

const _categoryIcons = <SyncCategory, IconData>{
  SyncCategory.favourites: FluentIcons.heart_24_regular,
  SyncCategory.playlists: FluentIcons.album_24_regular,
  SyncCategory.recent: FluentIcons.history_24_regular,
  SyncCategory.recap: FluentIcons.data_bar_vertical_24_regular,
  SyncCategory.searches: FluentIcons.search_24_regular,
  SyncCategory.radio: FluentIcons.live_24_regular,
};

IconData _deviceIcon(String name) => name.toLowerCase().contains('android')
    ? FluentIcons.phone_24_regular
    : FluentIcons.desktop_24_regular;

Future<void> _setLocalSync(BuildContext context, bool enabled) async {
  final service = LocalSyncService.instance;
  final started = await service.setEnabled(enabled);
  if (!context.mounted) return;
  if (!started) {
    showToast(
      context,
      context.l10n!.syncCouldNotStart,
      icon: FluentIcons.error_circle_24_regular,
    );
  } else if (enabled) {
    unawaited(service.startDiscovery());
  }
}

/// The Settings entry: on/off plus the last sync, opening [LocalSyncPage].
class LocalSyncSettingsSection extends StatelessWidget {
  const LocalSyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!LocalSyncService.instance.isSupportedPlatform) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n!;

    return Column(
      children: [
        SectionHeader(
          title: l10n.syncTitle,
          icon: FluentIcons.phone_desktop_24_filled,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: localSyncEnabled,
          builder: (context, enabled, _) => ValueListenableBuilder<DateTime?>(
            valueListenable: localSyncLastSyncedAt,
            builder: (context, lastSynced, _) => CustomBar(
              l10n.syncOverNetwork,
              FluentIcons.arrow_sync_24_regular,
              description: enabled
                  ? _lastSyncText(context, lastSynced)
                  : l10n.syncOffDescription,
              borderRadius: commonCustomBarRadius,
              onTap: () => context.push('/settings/local-sync'),
              trailing: Switch(
                value: enabled,
                onChanged: (value) => _setLocalSync(context, value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _lastSyncText(BuildContext context, DateTime? lastSynced) {
  if (lastSynced == null) return context.l10n!.syncFindDevices;
  final local = lastSynced.toLocal();
  final material = MaterialLocalizations.of(context);
  return context.l10n!.syncLastSynced(
    '${material.formatShortDate(local)} '
    '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}',
  );
}

/// Shows the PIN another device must type; listens to
/// [LocalSyncService.incomingPairingRequest].
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
        final theme = Theme.of(dialogContext);
        final l10n = dialogContext.l10n!;
        return AlertDialog(
          icon: Icon(
            _deviceIcon(request.clientName),
            color: theme.colorScheme.primary,
            size: 32,
          ),
          title: Text(l10n.syncPairTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.syncPairDescription(request.clientName),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _PinDigits(request.pin),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                LocalSyncService.instance.rejectIncomingPairing();
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.cancel),
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

class _PinDigits extends StatelessWidget {
  const _PinDigits(this.pin);

  final String pin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < pin.length; i++)
          Container(
            width: 40,
            height: 52,
            margin: EdgeInsets.only(left: i == 0 ? 0 : (i == 3 ? 14 : 6)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              pin[i],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}

/// This device, what to sync, and the devices on the network.
class LocalSyncPage extends StatefulWidget {
  const LocalSyncPage({super.key});

  @override
  State<LocalSyncPage> createState() => _LocalSyncPageState();
}

class _LocalSyncPageState extends State<LocalSyncPage> {
  final _service = LocalSyncService.instance;
  final _pinController = TextEditingController();

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
      appBar: AppBar(title: Text(context.l10n!.syncTitle)),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: ValueListenableBuilder<bool>(
              valueListenable: localSyncEnabled,
              builder: (context, enabled, _) => Column(
                children: [
                  _buildThisDevice(context, enabled),
                  if (enabled) ...[
                    _buildCategories(context),
                    ValueListenableBuilder<LocalSyncState>(
                      valueListenable: _service.state,
                      builder: (context, state, _) =>
                          _buildDevices(context, state),
                    ),
                  ] else
                    _buildOffHint(context),
                  const SizedBox(height: 20),
                  const MiniPlayerBottomSpace(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThisDevice(BuildContext context, bool enabled) {
    final l10n = context.l10n!;
    return Column(
      children: [
        SectionHeader(
          title: l10n.syncThisDevice,
          icon: FluentIcons.phone_desktop_24_filled,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _service.serverRunning,
          builder: (context, running, _) => CustomBar(
            _service.deviceName,
            isAndroidPlatform
                ? FluentIcons.phone_24_regular
                : FluentIcons.desktop_24_regular,
            description: !enabled
                ? l10n.syncOffDescription
                : running
                ? l10n.syncVisible
                : l10n.syncNotVisible,
            borderRadius: enabled
                ? commonCustomBarRadiusFirst
                : commonCustomBarRadius,
            onTap: () => _setLocalSync(context, !enabled),
            trailing: Switch(
              value: enabled,
              onChanged: (value) => _setLocalSync(context, value),
            ),
          ),
        ),
        if (enabled)
          ValueListenableBuilder<bool>(
            valueListenable: localSyncAutomatic,
            builder: (context, automatic, _) => CustomBar(
              l10n.syncAutomatic,
              FluentIcons.arrow_clockwise_24_regular,
              description: l10n.syncAutomaticDescription,
              borderRadius: commonCustomBarRadiusLast,
              onTap: () => _service.setAutomatic(!automatic),
              trailing: Switch(
                value: automatic,
                onChanged: _service.setAutomatic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOffHint(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
            FluentIcons.shield_checkmark_24_regular,
            size: 40,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n!.syncIsOff,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final l10n = context.l10n!;
    final labels = syncCategoryLabels(l10n);
    final selected = _service.selectedCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.syncData, icon: FluentIcons.list_24_filled),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 2 : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: constraints.maxWidth / columns / 76,
              children: [
                for (final category in SyncCategory.values)
                  BottomSheetBar(
                    labels[category]!,
                    () => _toggleCategory(category),
                    selected.contains(category),
                    icon: _categoryIcons[category],
                  ),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Text(
            l10n.syncSelections,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleCategory(SyncCategory category) async {
    final selected = _service.selectedCategories;
    if (!selected.remove(category)) selected.add(category);
    await _service.setCategories(selected);
    if (mounted) setState(() {});
  }

  Widget _buildDevices(BuildContext context, LocalSyncState state) {
    final l10n = context.l10n!;
    final busy =
        state.status != LocalSyncStatus.idle &&
        state.status != LocalSyncStatus.success &&
        state.status != LocalSyncStatus.error;

    return ValueListenableBuilder<List<PairedSyncDevice>>(
      valueListenable: _service.pairedDevices,
      builder: (context, paired, _) {
        final online = {
          for (final device in state.discoveredDevices) device.deviceId: device,
        };
        final pairedIds = paired.map((device) => device.deviceId).toSet();
        final others = online.values
            .where((device) => !pairedIds.contains(device.deviceId))
            .toList();

        return Column(
          children: [
            SectionHeader(
              title: l10n.syncDevices,
              icon: FluentIcons.wifi_1_24_filled,
              actionButton: IconButton(
                icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
                tooltip: l10n.syncScanAgain,
                onPressed: busy ? null : _service.startDiscovery,
              ),
            ),
            if (state.status != LocalSyncStatus.idle)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStatus(context, state),
              ),
            for (var i = 0; i < paired.length; i++)
              _buildPairedDevice(
                context,
                paired[i],
                online[paired[i].deviceId],
                getItemBorderRadius(i, paired.length),
                busy,
              ),
            if (paired.isNotEmpty && others.isNotEmpty)
              const SizedBox(height: 12),
            for (var i = 0; i < others.length; i++)
              CustomBar(
                others[i].name,
                _deviceIcon(others[i].name),
                description: others[i].ip,
                borderRadius: getItemBorderRadius(i, others.length),
                trailing: FilledButton.tonal(
                  onPressed: busy ? null : () => _service.syncWith(others[i]),
                  child: Text(l10n.syncPair),
                ),
              ),
            if (paired.isEmpty &&
                others.isEmpty &&
                state.status == LocalSyncStatus.idle)
              _buildNoDevices(context),
            if (paired.length > 1) ...[
              const SizedBox(height: 12),
              CustomBar(
                l10n.syncForgetAll,
                FluentIcons.link_dismiss_24_regular,
                iconColor: Theme.of(context).colorScheme.error,
                borderRadius: commonCustomBarRadius,
                onTap: () => _confirmForget(context, null),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPairedDevice(
    BuildContext context,
    PairedSyncDevice device,
    DiscoveredSyncDevice? online,
    BorderRadius borderRadius,
    bool busy,
  ) {
    final l10n = context.l10n!;
    return CustomBar(
      device.name,
      _deviceIcon(device.name),
      description: online != null
          ? l10n.syncOnline(online.ip)
          : l10n.syncOfflineDevice,
      iconColor: online != null ? Theme.of(context).colorScheme.primary : null,
      borderRadius: borderRadius,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (online != null)
            FilledButton.tonal(
              onPressed: busy ? null : () => _service.syncWith(online),
              child: Text(l10n.syncNow),
            ),
          IconButton(
            icon: const Icon(FluentIcons.link_dismiss_24_regular),
            tooltip: l10n.syncForget,
            onPressed: () => _confirmForget(context, device),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDevices(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _StatusCard(
      children: [
        Icon(
          FluentIcons.wifi_off_24_regular,
          size: 36,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(context.l10n!.syncNoDevices, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
          label: Text(context.l10n!.syncScanAgain),
          onPressed: _service.startDiscovery,
        ),
      ],
    );
  }

  Widget _buildStatus(BuildContext context, LocalSyncState state) {
    final theme = Theme.of(context);
    final l10n = context.l10n!;
    final name = state.activeDevice?.name ?? 'Musify';

    switch (state.status) {
      case LocalSyncStatus.idle:
        return const SizedBox.shrink();
      case LocalSyncStatus.scanning:
        return _StatusCard(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.syncScanning, textAlign: TextAlign.center),
          ],
        );
      case LocalSyncStatus.syncing:
        final (progress, label) = switch (state.stage) {
          LocalSyncStage.exporting => (0.2, l10n.syncPreparing),
          LocalSyncStage.exchanging => (0.5, l10n.syncSending),
          LocalSyncStage.merging => (0.85, l10n.syncMerging),
          null => (0.05, l10n.syncConnecting),
        };
        return _StatusCard(
          children: [
            Text(
              l10n.syncSyncingWith(name),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center),
          ],
        );
      case LocalSyncStatus.waitingForPin:
        return _StatusCard(
          children: [
            Icon(
              FluentIcons.link_24_regular,
              size: 36,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.syncPairWith(name),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(l10n.syncPinInstructions, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _pinController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: theme.textTheme.headlineSmall?.copyWith(
                  letterSpacing: 10,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '······',
                  counterText: '',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _submitPin(),
              ),
            ),
            const SizedBox(height: 16),
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
        );
      case LocalSyncStatus.success:
        final changed = state.changed ?? const {};
        final labels = syncCategoryLabels(l10n);
        final updated = [
          for (final category in SyncCategory.values)
            if (syncCategoryKeys[category]!.any(changed.contains)) category,
        ];
        return _StatusCard(
          children: [
            Icon(
              FluentIcons.checkmark_circle_24_filled,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.syncSyncedWith(name),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (updated.isEmpty)
              Text(l10n.syncUnchanged, textAlign: TextAlign.center)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final category in updated)
                    _Pill(_categoryIcons[category]!, labels[category]!),
                ],
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _service.resetStatus,
              child: Text(l10n.syncDone),
            ),
          ],
        );
      case LocalSyncStatus.error:
        return _StatusCard(
          children: [
            Icon(
              FluentIcons.error_circle_24_regular,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(_errorMessage(l10n, state, name), textAlign: TextAlign.center),
            const SizedBox(height: 16),
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
        );
    }
  }

  void _submitPin() {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      showToast(
        context,
        context.l10n!.syncPinInstructions,
        icon: FluentIcons.error_circle_24_regular,
      );
      return;
    }
    _pinController.clear();
    _service.submitPin(pin);
  }

  String _errorMessage(
    AppLocalizations l10n,
    LocalSyncState state,
    String name,
  ) {
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

  /// Forgets [device], or every paired device when null.
  void _confirmForget(BuildContext context, PairedSyncDevice? device) {
    final l10n = context.l10n!;
    showDialog<void>(
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: commonCustomBarRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
