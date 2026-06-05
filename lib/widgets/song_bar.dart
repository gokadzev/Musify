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
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/playlist_dialogs.dart';
import 'package:musify/widgets/no_artwork_cube.dart';
import 'package:musify/widgets/rename_song_dialog.dart';

Future<void> showSongBarMenu(
  BuildContext context,
  dynamic song, {
  Offset? globalPosition,
  bool isRecentSong = false,
  bool showQueueActions = true,
}) async {
  final ytid = _readSongYtid(song);
  if (ytid.isEmpty) return;

  final colorScheme = Theme.of(context).colorScheme;
  final songLikeStatus = ValueNotifier(isSongAlreadyLiked(ytid));
  final songOfflineStatus = ValueNotifier(isSongAlreadyOffline(ytid));

  try {
    final selected = await showMenu<String>(
      context: context,
      position: _songMenuPosition(context, globalPosition),
      items: _buildSongMenuItems(
        context: context,
        colorScheme: colorScheme,
        songLikeStatus: songLikeStatus,
        songOfflineStatus: songOfflineStatus,
        showQueueActions: showQueueActions,
        isRecentSong: isRecentSong,
      ),
    );

    if (selected == null || !context.mounted) return;

    await _handleSongMenuAction(
      context: context,
      value: selected,
      song: song,
      ytid: ytid,
      songLikeStatus: songLikeStatus,
      songOfflineStatus: songOfflineStatus,
    );
  } finally {
    songLikeStatus.dispose();
    songOfflineStatus.dispose();
  }
}

RelativeRect _songMenuPosition(BuildContext context, Offset? globalPosition) {
  final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
  if (overlay is RenderBox) {
    final position = globalPosition == null
        ? Offset(overlay.size.width / 2, overlay.size.height / 2)
        : overlay.globalToLocal(globalPosition);
    return RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 1, 1),
      Offset.zero & overlay.size,
    );
  }

  final size = MediaQuery.sizeOf(context);
  final position = globalPosition ?? Offset(size.width / 2, size.height / 2);
  return RelativeRect.fromRect(
    Rect.fromLTWH(position.dx, position.dy, 1, 1),
    Offset.zero & size,
  );
}

String _readSongYtid(dynamic song) =>
    song is Map ? song['ytid']?.toString() ?? '' : '';

List<PopupMenuEntry<String>> _buildSongMenuItems({
  required BuildContext context,
  required ColorScheme colorScheme,
  required ValueListenable<bool> songLikeStatus,
  required ValueListenable<bool> songOfflineStatus,
  required bool showQueueActions,
  bool isRecentSong = false,
  bool canRename = false,
  bool canRemove = false,
}) {
  final l10n = context.l10n!;
  final playNextText = l10n.playNext;
  final addToQueueText = l10n.addToQueue;
  final removeFromLikedSongsText = l10n.removeFromLikedSongs;
  final addToLikedSongsText = l10n.addToLikedSongs;
  final removeFromPlaylistText = l10n.removeFromPlaylist;
  final addToPlaylistText = l10n.addToPlaylist;
  final removeFromRecentlyPlayedText = l10n.removeFromRecentlyPlayed;
  final removeOfflineText = l10n.removeOffline;
  final makeOfflineText = l10n.makeOffline;
  final renameSongText = l10n.renameSong;

  return [
    if (showQueueActions)
      PopupMenuItem<String>(
        value: 'play_next',
        child: Row(
          children: [
            Icon(
              FluentIcons.receipt_play_24_regular,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(playNextText, style: TextStyle(color: colorScheme.secondary)),
          ],
        ),
      ),
    if (showQueueActions)
      PopupMenuItem<String>(
        value: 'add_to_queue',
        child: Row(
          children: [
            Icon(
              FluentIcons.text_bullet_list_add_24_regular,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              addToQueueText,
              style: TextStyle(color: colorScheme.secondary),
            ),
          ],
        ),
      ),
    if (!offlineMode.value)
      PopupMenuItem<String>(
        value: 'like',
        child: ValueListenableBuilder<bool>(
          valueListenable: songLikeStatus,
          builder: (_, value, __) {
            return Row(
              children: [
                Icon(
                  _SongBarState.likeStatusToIconMapper[value],
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  value ? removeFromLikedSongsText : addToLikedSongsText,
                  style: TextStyle(color: colorScheme.secondary),
                ),
              ],
            );
          },
        ),
      ),
    if (canRename)
      PopupMenuItem<String>(
        value: 'rename',
        child: Row(
          children: [
            Icon(FluentIcons.edit_24_regular, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              renameSongText,
              style: TextStyle(color: colorScheme.secondary),
            ),
          ],
        ),
      ),
    if (canRemove)
      PopupMenuItem<String>(
        value: 'remove',
        child: Row(
          children: [
            Icon(FluentIcons.delete_24_regular, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              removeFromPlaylistText,
              style: TextStyle(color: colorScheme.secondary),
            ),
          ],
        ),
      ),
    if (!offlineMode.value)
      PopupMenuItem<String>(
        value: 'add_to_playlist',
        child: Row(
          children: [
            Icon(FluentIcons.album_add_24_regular, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              addToPlaylistText,
              style: TextStyle(color: colorScheme.secondary),
            ),
          ],
        ),
      ),
    if (isRecentSong)
      PopupMenuItem<String>(
        value: 'remove_from_recents',
        child: Row(
          children: [
            Icon(FluentIcons.delete_24_regular, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              removeFromRecentlyPlayedText,
              style: TextStyle(color: colorScheme.secondary),
            ),
          ],
        ),
      ),
    if (!offlineMode.value || songOfflineStatus.value)
      PopupMenuItem<String>(
        value: 'offline',
        child: ValueListenableBuilder<bool>(
          valueListenable: songOfflineStatus,
          builder: (_, value, __) {
            return Row(
              children: [
                Icon(
                  value
                      ? FluentIcons.cloud_dismiss_24_regular
                      : FluentIcons.cloud_arrow_down_24_regular,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  value ? removeOfflineText : makeOfflineText,
                  style: TextStyle(color: colorScheme.secondary),
                ),
              ],
            );
          },
        ),
      ),
  ];
}

Future<void> _handleSongMenuAction({
  required BuildContext context,
  required String value,
  required dynamic song,
  required String ytid,
  required ValueNotifier<bool> songLikeStatus,
  required ValueNotifier<bool> songOfflineStatus,
  VoidCallback? onRemove,
  FutureOr<void> Function()? onRename,
}) async {
  switch (value) {
    case 'play_next':
      await audioHandler.playNext(song);
      showToast(
        context,
        context.l10n!.songAdded,
        duration: const Duration(seconds: 1),
      );
      break;
    case 'add_to_queue':
      await audioHandler.addToQueue(song);
      showToast(
        context,
        context.l10n!.songAdded,
        duration: const Duration(seconds: 1),
      );
      break;
    case 'like':
      final newValue = !songLikeStatus.value;
      songLikeStatus.value = newValue;
      showToast(
        context,
        newValue
            ? context.l10n!.addedToLikedSongs
            : context.l10n!.removedFromLikedSongs,
        duration: const Duration(seconds: 1),
      );
      try {
        await updateSongLikeStatus(ytid, newValue, songData: song);
      } catch (e) {
        logger.log('Error updating song like status', error: e);
        songLikeStatus.value = !newValue;
      }
      break;
    case 'remove':
      onRemove?.call();
      break;
    case 'rename':
      await onRename?.call();
      break;
    case 'add_to_playlist':
      showAddToPlaylistDialog(context, song: song);
      break;
    case 'remove_from_recents':
      try {
        await removeFromRecentlyPlayed(ytid);
      } catch (e) {
        logger.log('Error removing from recently played', error: e);
      }
      break;
    case 'offline':
      await _toggleSongOfflineStatus(context, song, ytid, songOfflineStatus);
      break;
  }
}

Future<void> _toggleSongOfflineStatus(
  BuildContext context,
  dynamic song,
  String ytid,
  ValueNotifier<bool> songOfflineStatus,
) async {
  final originalValue = songOfflineStatus.value;
  songOfflineStatus.value = !originalValue;

  try {
    final bool success;
    if (originalValue) {
      success = await removeSongFromOffline(ytid);
      if (success && context.mounted) {
        showToast(context, context.l10n!.songRemovedFromOffline);
      }
    } else {
      success = await makeSongOffline(song);
      if (success && context.mounted) {
        showToast(context, context.l10n!.songAddedToOffline);
      }
    }

    if (!success) {
      songOfflineStatus.value = originalValue;
    }
  } catch (e) {
    songOfflineStatus.value = originalValue;
    logger.log('Error toggling offline status', error: e);
    if (context.mounted) {
      showToast(context, context.l10n!.error);
    }
  }
}

class SongBar extends StatefulWidget {
  const SongBar(
    this.song,
    this.clearPlaylist, {
    this.backgroundColor,
    this.showMusicDuration = false,
    this.onPlay,
    this.isRecentSong,
    this.onRemove,
    this.borderRadius = BorderRadius.zero,
    this.isFromLikedSongs = false,
    this.showQueueActions = true,
    this.showPlayTime = false,
    this.playlistId,
    this.onRenamed,
    this.rank,
    super.key,
  });

  final dynamic song;
  final bool clearPlaylist;
  final Color? backgroundColor;
  final VoidCallback? onRemove;
  final VoidCallback? onPlay;
  final bool? isRecentSong;
  final bool showMusicDuration;
  final bool showPlayTime;
  final BorderRadius borderRadius;
  final bool isFromLikedSongs;
  final bool showQueueActions;
  final String? playlistId;
  final VoidCallback? onRenamed;
  final int? rank;

  @override
  State<SongBar> createState() => _SongBarState();
}

class _SongBarState extends State<SongBar> {
  static const _menuHitAreaWidth = 72.0;

  static const likeStatusToIconMapper = {
    true: FluentIcons.heart_off_24_regular,
    false: FluentIcons.heart_24_regular,
  };

  late final ValueNotifier<bool> _songLikeStatus;
  late final ValueNotifier<bool> _songOfflineStatus;
  late String _songTitle;
  late String _songArtist;
  late final String? _artworkPath;
  late final String _lowResImageUrl;
  late final String _ytid;

  @override
  void initState() {
    super.initState();

    // Cache frequently accessed values
    _songTitle = widget.song['title'] ?? '';
    _songArtist = widget.song['artist']?.toString() ?? '';
    _artworkPath = widget.song['artworkPath'];
    _lowResImageUrl = widget.song['lowResImage']?.toString() ?? '';
    _ytid = widget.song['ytid'] ?? '';

    // Initialize ValueNotifiers only once
    _songLikeStatus = ValueNotifier(isSongAlreadyLiked(_ytid));
    final isOffline = isSongAlreadyOffline(_ytid);
    _songOfflineStatus = ValueNotifier(isOffline);
    userLikedSongsList.addListener(_syncLikeStatus);
    userOfflineSongs.addListener(_syncOfflineStatus);
  }

  void _syncLikeStatus() {
    final newStatus = isSongAlreadyLiked(_ytid);
    if (_songLikeStatus.value != newStatus) {
      _songLikeStatus.value = newStatus;
    }
  }

  void _syncOfflineStatus() {
    final newStatus = isSongAlreadyOffline(_ytid);
    if (_songOfflineStatus.value != newStatus) {
      _songOfflineStatus.value = newStatus;
    }
  }

  @override
  void didUpdateWidget(SongBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update cached title and artist if they changed
    final newTitle = widget.song['title'] ?? '';
    final newArtist = widget.song['artist']?.toString() ?? '';

    if (_songTitle != newTitle || _songArtist != newArtist) {
      setState(() {
        _songTitle = newTitle;
        _songArtist = newArtist;
      });
    }
  }

  @override
  void dispose() {
    userLikedSongsList.removeListener(_syncLikeStatus);
    userOfflineSongs.removeListener(_syncOfflineStatus);
    _songLikeStatus.dispose();
    _songOfflineStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final _plays = widget.showPlayTime
        ? (widget.song['listeningCount'] is int)
              ? widget.song['listeningCount'] as int
              : int.tryParse(widget.song['listeningCount']?.toString() ?? '') ??
                    0
        : null;

    return Padding(
      padding: commonBarPadding,
      child: Material(
        color: widget.backgroundColor ?? colorScheme.surfaceContainerLow,
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _handleSongTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  12,
                  10,
                  _menuHitAreaWidth,
                  10,
                ),
                child: Row(
                  children: [
                    if (widget.rank != null) ...[
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${widget.rank}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    _buildAlbumArt(colorScheme),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SongInfo(
                        title: _songTitle,
                        artist: _songArtist,
                        plays: _plays,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 0,
                end: 0,
                bottom: 0,
                width: _menuHitAreaWidth,
                child: _buildActionButtons(context, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSongTap() {
    if (widget.onPlay != null) {
      widget.onPlay!();
      return;
    }

    if (widget.clearPlaylist) {
      audioHandler.addPlaylistToQueue([widget.song], replace: true);
    } else {
      audioHandler.playSong(widget.song);
    }
  }

  Widget _buildAlbumArt(ColorScheme colorScheme) {
    const size = 52.0;
    final isDurationAvailable =
        widget.showMusicDuration && widget.song['duration'] != null;

    return ValueListenableBuilder<bool>(
      valueListenable: _songOfflineStatus,
      builder: (_, isOffline, __) {
        if (isOffline && _artworkPath != null) {
          return _OfflineArtwork(
            artworkPath: _artworkPath,
            size: size,
            colorScheme: colorScheme,
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: _songLikeStatus,
          builder: (_, isLiked, __) {
            return _OnlineArtwork(
              lowResImageUrl: _lowResImageUrl,
              size: size,
              isDurationAvailable: isDurationAvailable,
              colorScheme: colorScheme,
              duration: widget.song['duration'],
              isOffline: isOffline,
              isLiked: isLiked,
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      borderRadius: BorderRadius.circular(_menuHitAreaWidth / 2),
      padding: EdgeInsets.zero,
      splashRadius: 28,
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => _buildMenuItems(context, colorScheme),
      child: Center(
        child: Icon(
          FluentIcons.more_vertical_24_regular,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String value) {
    unawaited(
      _handleSongMenuAction(
        context: context,
        value: value,
        song: widget.song,
        ytid: _ytid,
        songLikeStatus: _songLikeStatus,
        songOfflineStatus: _songOfflineStatus,
        onRemove: widget.onRemove,
        onRename: () => _handleRenameSong(context),
      ),
    );
  }

  void _handleRenameSong(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RenameSongDialog(
        currentTitle: _songTitle,
        currentArtist: _songArtist,
        onRename: (newTitle, newArtist) {
          _renameSong(newTitle, newArtist, context);
        },
      ),
    );
  }

  Future<void> _renameSong(
    String newTitle,
    String newArtist,
    BuildContext context,
  ) async {
    try {
      if (widget.isFromLikedSongs) {
        await renameSongInLikedSongs(_ytid, newTitle, newArtist);
        widget.song['title'] = newTitle;
        widget.song['artist'] = newArtist;
        if (context.mounted) {
          setState(() {
            _songTitle = newTitle;
            _songArtist = newArtist;
          });
          showToast(context, context.l10n!.settingChangedMsg);
        }
      } else if (widget.playlistId != null) {
        await renameSongInPlaylist(
          widget.playlistId,
          _ytid,
          newTitle,
          newArtist,
        );
        widget.song['title'] = newTitle;
        widget.song['artist'] = newArtist;
        if (context.mounted) {
          setState(() {
            _songTitle = newTitle;
            _songArtist = newArtist;
          });
          showToast(context, context.l10n!.settingChangedMsg);
          widget.onRenamed?.call();
        }
      }
    } catch (e, stackTrace) {
      logger.log('Error renaming song', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        showToast(context, context.l10n!.error);
      }
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final canRename = widget.isFromLikedSongs || widget.playlistId != null;
    return _buildSongMenuItems(
      context: context,
      colorScheme: colorScheme,
      songLikeStatus: _songLikeStatus,
      songOfflineStatus: _songOfflineStatus,
      showQueueActions: widget.showQueueActions,
      isRecentSong: widget.isRecentSong == true,
      canRename: canRename,
      canRemove: widget.onRemove != null,
    );
  }
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({
    required this.title,
    required this.artist,
    this.plays,
    required this.colorScheme,
  });

  final String title;
  final String artist;
  final int? plays;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                artist,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (plays != null && plays! > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                FluentIcons.headphones_20_filled,
                size: 12,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 3),
              Text(
                '$plays',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _OfflineArtwork extends StatelessWidget {
  const _OfflineArtwork({
    required this.artworkPath,
    required this.size,
    required this.colorScheme,
  });

  final String artworkPath;
  final double size;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Image.file(
              File(artworkPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const NullArtworkWidget(iconSize: 30),
            ),
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FluentIcons.cloud_off_24_filled,
                  size: 11,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineArtwork extends StatelessWidget {
  const _OnlineArtwork({
    required this.lowResImageUrl,
    required this.size,
    required this.isDurationAvailable,
    required this.colorScheme,
    required this.duration,
    required this.isOffline,
    required this.isLiked,
  });

  final String lowResImageUrl;
  final double size;
  final bool isDurationAvailable;
  final ColorScheme colorScheme;
  final dynamic duration;
  final bool isOffline;
  final bool isLiked;

  @override
  Widget build(BuildContext context) {
    final isImageSmall = lowResImageUrl.contains('default.jpg');

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CachedNetworkImage(
            imageUrl: lowResImageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            memCacheWidth: 256,
            memCacheHeight: 256,
            imageBuilder: (context, imageProvider) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Image(
                    image: imageProvider,
                    fit: isImageSmall ? BoxFit.fill : BoxFit.cover,
                    width: size,
                    height: size,
                    centerSlice: isImageSmall
                        ? const Rect.fromLTRB(1, 1, 1, 1)
                        : null,
                  ),
                  if (isOffline)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FluentIcons.cloud_off_24_filled,
                          size: 11,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    )
                  else if (isLiked)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FluentIcons.heart_24_filled,
                          size: 11,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            errorWidget: (context, url, error) =>
                const NullArtworkWidget(iconSize: 30),
          ),
          if (isDurationAvailable && !isOffline)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.85,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  formatDuration(duration),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
