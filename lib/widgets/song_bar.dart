/*
 *     Copyright (C) 2025 Valeri Gokadze
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
  late final String _songTitle;
  late final String _songArtist;
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
    _songOfflineStatus = ValueNotifier(
      widget.isSongOffline ?? isSongAlreadyOffline(_ytid),
    );
  }

  @override
  void dispose() {
    _songLikeStatus.dispose();
    _songOfflineStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: commonBarPadding,
      child: GestureDetector(
        onTap: _handleSongTap,
        child: Card(
          color: widget.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
          margin: const EdgeInsets.only(bottom: 3),
          child: Padding(
            padding: commonBarContentPadding,
            child: Row(
              children: [
                _buildAlbumArt(primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: _SongInfo(
                    title: _songTitle,
                    artist: _songArtist,
                    primaryColor: primaryColor,
                    secondaryColor: theme.colorScheme.secondary,
                  ),
                ),
                _buildActionButtons(context, primaryColor),
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

    audioHandler.playSong(widget.song);
    if (activePlaylist.isNotEmpty && widget.clearPlaylist) {
      activePlaylist = {
        'ytid': '',
        'title': 'No Playlist',
        'image': '',
        'source': 'user-created',
        'list': [],
      };
      activeSongId = 0;
    }
  }

  Widget _buildAlbumArt(Color primaryColor) {
    const size = 55.0;
    final isDurationAvailable =
        widget.showMusicDuration && widget.song['duration'] != null;

    if (_artworkPath != null) {
      return _OfflineArtwork(artworkPath: _artworkPath, size: size);
    }

    return _OnlineArtwork(
      lowResImageUrl: _lowResImageUrl,
      size: size,
      isDurationAvailable: isDurationAvailable,
      primaryColor: primaryColor,
      duration: widget.song['duration'],
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surface,
      icon: Icon(FluentIcons.more_horizontal_24_filled, color: primaryColor),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => _buildMenuItems(context, primaryColor),
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
      case 'like':
        _songLikeStatus.value = !_songLikeStatus.value;
        updateSongLikeStatus(_ytid, _songLikeStatus.value);
        final likedSongsLength = currentLikedSongsLength.value;
        currentLikedSongsLength.value =
            _songLikeStatus.value ? likedSongsLength + 1 : likedSongsLength - 1;
        break;
      case 'remove':
        widget.onRemove?.call();
        break;
      case 'add_to_playlist':
        showAddToPlaylistDialog(context, widget.song);
        break;
      case 'remove_from_recents':
        removeFromRecentlyPlayed(_ytid);
        break;
      case 'offline':
        _handleOfflineToggle(context);
        break;
    }
  }

  void _handleOfflineToggle(BuildContext context) {
    if (_songOfflineStatus.value) {
      removeSongFromOffline(_ytid).then((success) {
        if (success) {
          showToast(context, context.l10n!.songRemovedFromOffline);
        }
      });
    } else {
      makeSongOffline(widget.song).then((success) {
        if (success) {
          showToast(context, context.l10n!.songAddedToOffline);
        }
      });
    }
    _songOfflineStatus.value = !_songOfflineStatus.value;
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    Color primaryColor,
  ) {
    return [
      PopupMenuItem<String>(
        value: 'play_next',
        child: Row(
          children: [
            Icon(FluentIcons.receipt_play_24_regular, color: primaryColor),
            const SizedBox(width: 8),
            Text(context.l10n!.playNext),
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
                Icon(likeStatusToIconMapper[value], color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  value
                      ? context.l10n!.removeFromLikedSongs
                      : context.l10n!.addToLikedSongs,
                ),
              ],
            );
          },
        ),
      ),
      if (widget.onRemove != null)
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(FluentIcons.delete_24_filled, color: primaryColor),
              const SizedBox(width: 8),
              Text(context.l10n!.removeFromPlaylist),
            ],
          ),
        ),
      PopupMenuItem<String>(
        value: 'add_to_playlist',
        child: Row(
          children: [
            Icon(FluentIcons.add_24_regular, color: primaryColor),
            const SizedBox(width: 8),
            Text(context.l10n!.addToPlaylist),
          ],
        ),
      ),
      if (widget.isRecentSong == true)
        PopupMenuItem<String>(
          value: 'remove_from_recents',
          child: Row(
            children: [
              Icon(FluentIcons.delete_24_filled, color: primaryColor),
              const SizedBox(width: 8),
              Text(context.l10n!.removeFromRecentlyPlayed),
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
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  value
                      ? context.l10n!.removeOffline
                      : context.l10n!.makeOffline,
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
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String title;
  final String artist;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: commonBarTitleStyle.copyWith(color: primaryColor),
        ),
        const SizedBox(height: 3),
        Text(
          artist,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }
}

class _OfflineArtwork extends StatelessWidget {
  const _OfflineArtwork({required this.artworkPath, required this.size});

  final String artworkPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: commonBarRadius,
        child: Image.file(
          File(artworkPath),
          fit: BoxFit.cover,
          cacheWidth: 256,
          cacheHeight: 256,
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
    required this.primaryColor,
    required this.duration,
  });

  final String lowResImageUrl;
  final double size;
  final bool isDurationAvailable;
  final Color primaryColor;
  final dynamic duration;

  @override
  Widget build(BuildContext context) {
    final isImageSmall = lowResImageUrl.contains('default.jpg');

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        CachedNetworkImage(
          key: ValueKey(lowResImageUrl),
          width: size,
          height: size,
          imageUrl: lowResImageUrl,
          memCacheWidth: 256,
          memCacheHeight: 256,
          imageBuilder:
              (context, imageProvider) => SizedBox(
                width: size,
                height: size,
                child: ClipRRect(
                  borderRadius: commonBarRadius,
                  child: Image(
                    color:
                        isDurationAvailable
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                    colorBlendMode:
                        isDurationAvailable ? BlendMode.multiply : null,
                    opacity:
                        isDurationAvailable
                            ? const AlwaysStoppedAnimation(0.45)
                            : null,
                    image: imageProvider,
                    centerSlice:
                        isImageSmall ? const Rect.fromLTRB(1, 1, 1, 1) : null,
                  ),
                ),
              ),
          errorWidget:
              (context, url, error) => const NullArtworkWidget(iconSize: 30),
        ),
        if (isDurationAvailable)
          SizedBox(
            width: size - 10,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '(${formatDuration(duration)})',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
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
          child:
              userCustomPlaylists.value.isNotEmpty
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
