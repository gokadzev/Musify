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
import 'package:musify/models/radio_model.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/utilities/artwork_provider.dart';

class RadioStationCard extends StatefulWidget {
  const RadioStationCard({
    super.key,
    required this.station,
    required this.onPressed,
    this.onFavoritesChanged,
  });

  final RadioStation station;
  final VoidCallback onPressed;
  final VoidCallback? onFavoritesChanged;

  @override
  State<RadioStationCard> createState() => _RadioStationCardState();
}

class _RadioStationCardState extends State<RadioStationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late ValueNotifier<bool> _isFavorited;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1, end: 0.85).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _isFavorited = ValueNotifier<bool>(isRadioStationLiked(widget.station.id));
    userLikedRadioStations.addListener(_onFavoritesUpdated);
  }

  void _onFavoritesUpdated() {
    final newStatus = isRadioStationLiked(widget.station.id);
    if (_isFavorited.value != newStatus) {
      _isFavorited.value = newStatus;
    }
  }

  @override
  void dispose() {
    userLikedRadioStations.removeListener(_onFavoritesUpdated);
    _isFavorited.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  Future<void> _handleFavoriteTap() async {
    if (isRadioStationLiked(widget.station.id)) {
      await removeRadioStationFromLiked(widget.station.id);
    } else {
      await addRadioStationToLiked(widget.station.id);
    }
    widget.onFavoritesChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _opacityAnimation,
          builder: (context, child) =>
              Opacity(opacity: _opacityAnimation.value, child: child),
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Material(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    /// Album artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(
                        image: ArtworkProvider.get(widget.station.image),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              FluentIcons.speaker_2_24_filled,
                              color: colorScheme.onPrimaryContainer,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    /// Station details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /// Station name
                          Text(
                            widget.station.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          /// Genre label
                          if (widget.station.genre != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.station.genre!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                            Text(
                              'Radio Station',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    /// Favorite and play buttons
                    const SizedBox(width: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isFavorited,
                      builder: (context, isFavorited, _) {
                        return GestureDetector(
                          onTap: _handleFavoriteTap,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isFavorited
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              isFavorited
                                  ? FluentIcons.heart_24_filled
                                  : FluentIcons.heart_24_regular,
                              color: isFavorited
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),

                    /// Play button
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        FluentIcons.play_24_filled,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
