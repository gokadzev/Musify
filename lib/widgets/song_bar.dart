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

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/widgets/no_artwork_cube.dart';
import 'package:musify/widgets/rename_song_dialog.dart';

class SongBar extends StatefulWidget {
  const SongBar(
    this.song,
    this.clearPlaylist, {
    this.backgroundColor,
    this.showMusicDuration = false,
    this.onPlay,
    this.isSongOffline,
    this.isRecentSong,
    this.onRemove,
    this.borderRadius = BorderRadius.zero,
    this.isFromLikedSongs = false,
    this.playlistId,
    this.onRenamed,
    super.key,
  });

  final dynamic song;
  final bool clearPlaylist;
  final Color? backgroundColor;
  final VoidCallback? onRemove;
  final VoidCallback? onPlay;
  final bool? isSongOffline;
  final bool? isRecentSong;
  final bool showMusicDuration;
  final BorderRadius borderRadius;
  final bool isFromLikedSongs;
  final String? playlistId;
  final VoidCallback? onRenamed;

  @override
  State<SongBar> createState() => _SongBarState();
}

class _SongBarState extends State<SongBar> {
  static const likeStatusToIconMapper = {
    true: FluentIcons.heart_24_filled,
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
    final isOffline =
        widget.isSongOffline ??
        (widget.song['isOffline'] ?? isSongAlreadyOffline(_ytid));
    _songOfflineStatus = ValueNotifier(isOffline);
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
    _songLikeStatus.dispose();
    _songOfflineStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: commonBarPadding,
      child: Card(
        color: widget.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
        margin: const EdgeInsets.only(bottom: 3),
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: _handleSongTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                _buildAlbumArt(colorScheme),
                const SizedBox(width: 12),
                Expanded(
                  child: _SongInfo(
                    title: _songTitle,
                    artist: _songArtist,
                    colorScheme: colorScheme,
                  ),
                ),
                _buildActionButtons(context, colorScheme),
              ],
            ),
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
    const size = 48.0;
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

        return _OnlineArtwork(
          lowResImageUrl: _lowResImageUrl,
          size: size,
          isDurationAvailable: isDurationAvailable,
          colorScheme: colorScheme,
          duration: widget.song['duration'],
          isOffline: isOffline,
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      icon: Icon(
        FluentIcons.more_horizontal_24_filled,
        color: colorScheme.onSurfaceVariant,
      ),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => _buildMenuItems(context, colorScheme),
    );
  }

  void _handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'play_next':
        audioHandler.playNext(widget.song);
        showToast(
          context,
          context.l10n!.songAdded,
          duration: const Duration(seconds: 1),
        );
        break;
      case 'add_to_queue':
        audioHandler.addToQueue(widget.song);
        showToast(
          context,
          context.l10n!.songAdded,
          duration: const Duration(seconds: 1),
        );
        break;
      case 'like':
        final newValue = !_songLikeStatus.value;
        _songLikeStatus.value = newValue;
        final likedSongsLength = currentLikedSongsLength.value;
        currentLikedSongsLength.value = newValue
            ? likedSongsLength + 1
            : likedSongsLength - 1;
        updateSongLikeStatus(_ytid, newValue).catchError((e) {
          logger.log('Error updating song like status', e, null);
          // Revert on error
          _songLikeStatus.value = !newValue;
          currentLikedSongsLength.value = likedSongsLength;
        });
        showToast(
          context,
          newValue
              ? context.l10n!.addedToLikedSongs
              : context.l10n!.removedFromLikedSongs,
          duration: const Duration(seconds: 1),
        );
        break;
      case 'remove':
        widget.onRemove?.call();
        break;
      case 'rename':
        _handleRenameSong(context);
        break;
      case 'add_to_playlist':
        showAddToPlaylistDialog(context, widget.song);
        break;
      case 'remove_from_recents':
        removeFromRecentlyPlayed(_ytid).catchError((e) {
          logger.log('Error removing from recently played', e, null);
        });
        break;
      case 'offline':
        _handleOfflineToggle(context);
        break;
    }
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
        // Update local cached values
        widget.song['title'] = newTitle;
        widget.song['artist'] = newArtist;
        if (context.mounted) {
          showToast(context, context.l10n!.settingChangedMsg);
          // Force rebuild by triggering value change
          // Temporarily change the value to force ValueListenableBuilder to rebuild
          final oldValue = currentLikedSongsLength.value;
          currentLikedSongsLength.value = oldValue + 1;
          currentLikedSongsLength.value = oldValue;
        }
      } else if (widget.playlistId != null) {
        await renameSongInPlaylist(
          widget.playlistId,
          _ytid,
          newTitle,
          newArtist,
        );
        // Update local cached values
        widget.song['title'] = newTitle;
        widget.song['artist'] = newArtist;
        if (context.mounted) {
          showToast(context, context.l10n!.settingChangedMsg);
          // Trigger parent page rebuild for custom playlists
          widget.onRenamed?.call();
        }
      }
    } catch (e, stackTrace) {
      logger.log('Error renaming song', e, stackTrace);
      if (context.mounted) {
        showToast(context, context.l10n!.error);
      }
    }
  }

  void _handleOfflineToggle(BuildContext context) async {
    final originalValue = _songOfflineStatus.value;
    _songOfflineStatus.value = !originalValue;

    try {
      final bool success;
      if (originalValue) {
        success = await removeSongFromOffline(_ytid);
        if (success && context.mounted) {
          showToast(context, context.l10n!.songRemovedFromOffline);
        }
      } else {
        success = await makeSongOffline(widget.song);
        if (success && context.mounted) {
          showToast(context, context.l10n!.songAddedToOffline);
        }
      }

      // Revert if operation failed
      if (!success) {
        _songOfflineStatus.value = originalValue;
      }
    } catch (e) {
      // Revert on error
      _songOfflineStatus.value = originalValue;
      logger.log('Error toggling offline status', e, null);
      if (context.mounted) {
        showToast(context, context.l10n!.error);
      }
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    // Capture localization strings before building menu items to avoid
    // accessing context.l10n inside ValueListenableBuilder which can fail
    // when the widget is being disposed
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
    final canRename = widget.isFromLikedSongs || widget.playlistId != null;

    return [
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
      PopupMenuItem<String>(
        value: 'add_to_queue',
        child: Row(
          children: [
            Icon(FluentIcons.add_24_regular, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              addToQueueText,
              style: TextStyle(color: colorScheme.secondary),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'like',
        child: ValueListenableBuilder<bool>(
          valueListenable: _songLikeStatus,
          builder: (_, value, __) {
            return Row(
              children: [
                Icon(likeStatusToIconMapper[value], color: colorScheme.primary),
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
      if (widget.onRemove != null)
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(FluentIcons.delete_24_filled, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                removeFromPlaylistText,
                style: TextStyle(color: colorScheme.secondary),
              ),
            ],
          ),
        ),
      PopupMenuItem<String>(
        value: 'add_to_playlist',
        child: Row(
          children: [
            Icon(FluentIcons.add_24_regular, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              addToPlaylistText,
              style: TextStyle(color: colorScheme.secondary),
            ),
          ],
        ),
      ),
      if (widget.isRecentSong == true)
        PopupMenuItem<String>(
          value: 'remove_from_recents',
          child: Row(
            children: [
              Icon(FluentIcons.delete_24_filled, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                removeFromRecentlyPlayedText,
                style: TextStyle(color: colorScheme.secondary),
              ),
            ],
          ),
        ),
      PopupMenuItem<String>(
        value: 'offline',
        child: ValueListenableBuilder<bool>(
          valueListenable: _songOfflineStatus,
          builder: (_, value, __) {
            return Row(
              children: [
                Icon(
                  value
                      ? FluentIcons.cellular_off_24_regular
                      : FluentIcons.cellular_data_1_24_regular,
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
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({
    required this.title,
    required this.artist,
    required this.colorScheme,
  });

  final String title;
  final String artist;
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
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          artist,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
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
          alignment: Alignment.center,
          children: [
            Image.file(
              File(artworkPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              color: colorScheme.primaryContainer,
              colorBlendMode: BlendMode.multiply,
              opacity: const AlwaysStoppedAnimation(0.45),
            ),
            Icon(
              FluentIcons.cellular_off_24_filled,
              size: 20,
              color: colorScheme.primary,
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
  });

  final String lowResImageUrl;
  final double size;
  final bool isDurationAvailable;
  final ColorScheme colorScheme;
  final dynamic duration;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final isImageSmall = lowResImageUrl.contains('default.jpg');
    final shouldOverlayBeShown =
        (isDurationAvailable && !isOffline) || isOffline;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CachedNetworkImage(
            key: ValueKey(lowResImageUrl),
            imageUrl: lowResImageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            memCacheWidth: 256,
            memCacheHeight: 256,
            imageBuilder: (context, imageProvider) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image(
                    color: shouldOverlayBeShown
                        ? colorScheme.primaryContainer
                        : null,
                    colorBlendMode: shouldOverlayBeShown
                        ? BlendMode.multiply
                        : null,
                    opacity: shouldOverlayBeShown
                        ? const AlwaysStoppedAnimation(0.45)
                        : null,
                    image: imageProvider,
                    fit: isImageSmall ? BoxFit.fill : BoxFit.cover,
                    width: size,
                    height: size,
                    centerSlice: isImageSmall
                        ? const Rect.fromLTRB(1, 1, 1, 1)
                        : null,
                  ),
                  if (isOffline)
                    Icon(
                      FluentIcons.cellular_off_24_filled,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ),
            errorWidget: (context, url, error) =>
                const NullArtworkWidget(iconSize: 30),
          ),
          if (isDurationAvailable && !isOffline)
            Text(
              '(${formatDuration(duration)})',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

void showAddToPlaylistDialog(BuildContext context, dynamic song) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        icon: const Icon(FluentIcons.text_bullet_list_add_24_filled),
        title: Text(context.l10n!.addToPlaylist),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: userCustomPlaylists.value.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: userCustomPlaylists.value.length,
                  itemBuilder: (context, index) {
                    final playlist = userCustomPlaylists.value[index];
                    return Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      elevation: 0,
                      child: ListTile(
                        title: Text(playlist['title']),
                        onTap: () {
                          showToast(
                            context,
                            addSongInCustomPlaylist(
                              context,
                              playlist['title'],
                              song,
                            ),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                )
              : Text(
                  context.l10n!.noCustomPlaylists,
                  textAlign: TextAlign.center,
                ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.l10n!.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
