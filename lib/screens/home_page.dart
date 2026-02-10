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
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/async_loader.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/announcement_box.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/section_header.dart';
import 'package:musify/widgets/song_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _suggestedPlaylistsController;
  late final PageController _likedPlaylistsController;
  Timer? _suggestedAutoTimer;
  Timer? _suggestedResumeTimer;
  int _suggestedItemCount = 0;
  bool _suggestedAutoPaused = false;

  @override
  void initState() {
    super.initState();
    _suggestedPlaylistsController = PageController(viewportFraction: 0.68);
    _likedPlaylistsController = PageController(viewportFraction: 0.68);
  }

  @override
  void dispose() {
    _suggestedAutoTimer?.cancel();
    _suggestedResumeTimer?.cancel();
    _suggestedPlaylistsController.dispose();
    _likedPlaylistsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistHeight = MediaQuery.sizeOf(context).height * 0.25 / 1.1;
    return Scaffold(
      appBar: AppBar(title: const Text('Musify.')),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: announcementURL,
              builder: (_, _url, __) {
                if (_url == null) return const SizedBox.shrink();

                return AnnouncementBox(
                  message: context.l10n!.newAnnouncement,
                  url: _url,
                  onDismiss: () async {
                    announcementURL.value = null;
                  },
                );
              },
            ),
            _buildSuggestedPlaylists(playlistHeight),
            _buildSuggestedPlaylists(playlistHeight, showOnlyLiked: true),
            _buildRecommendedSongsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaylists(
    double playlistHeight, {
    bool showOnlyLiked = false,
  }) {
    final sectionTitle = showOnlyLiked
        ? context.l10n!.backToFavorites
        : context.l10n!.suggestedPlaylists;
    return AsyncLoader<List<dynamic>>(
      future: getPlaylists(
        playlistsNum: recommendedCubesNumber,
        onlyLiked: showOnlyLiked,
      ),

      builder: (context, playlists) {
        final itemsNumber = playlists.length.clamp(0, recommendedCubesNumber);
        final controller = showOnlyLiked
            ? _likedPlaylistsController
            : _suggestedPlaylistsController;
        if (!showOnlyLiked) {
          _suggestedItemCount = itemsNumber;
          _startSuggestedAutoScroll();
        }

        return Column(
          children: [
            SectionHeader(
              title: sectionTitle,
              icon: showOnlyLiked
                  ? FluentIcons.heart_24_filled
                  : FluentIcons.list_24_filled,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: playlistHeight),
              child: _buildAdvancedScroller(
                playlists,
                itemsNumber,
                playlistHeight,
                controller,
                enableAutoScroll: !showOnlyLiked,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedScroller(
    List<dynamic> playlists,
    int itemCount,
    double height,
    PageController controller, {
    bool enableAutoScroll = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseSize = height * 0.9;
    Widget scroller = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: PageView.builder(
        controller: controller,
        itemCount: itemCount,
        padEnds: false,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final page = controller.hasClients
                  ? (controller.page ?? controller.initialPage.toDouble())
                  : controller.initialPage.toDouble();
              final distance = (page - index).abs().clamp(0.0, 1.0);
              final scale = 1 - (distance * 0.12);
              final tilt = (page - index) * 0.05;
              final translateY = distance * 10;
              final glowOpacity = (1 - distance * 0.7).clamp(0.0, 1.0);

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.rotate(
                  angle: tilt,
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: (1 - distance * 0.2).clamp(0.0, 1.0),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlaylistPage(playlistId: playlist['ytid']),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.12 * glowOpacity,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: PlaylistCube(
                                    playlist,
                                    size: baseSize,
                                    borderRadius: 22,
                                  ),
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          colorScheme.surface.withValues(
                                            alpha: 0.15,
                                          ),
                                          colorScheme.surface.withValues(
                                            alpha: 0.75,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 14,
                                  right: 14,
                                  bottom: 12,
                                  child: Text(
                                    playlist['title']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    if (!enableAutoScroll) return scroller;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          _pauseSuggestedAutoScroll();
        } else if (notification is ScrollEndNotification) {
          _pauseSuggestedAutoScroll(resumeDelay: const Duration(seconds: 3));
        }
        return false;
      },
      child: scroller,
    );
  }

  void _startSuggestedAutoScroll() {
    if (_suggestedAutoTimer != null || _suggestedItemCount < 2) return;

    _suggestedAutoTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!mounted || _suggestedAutoPaused) return;
        if (!_suggestedPlaylistsController.hasClients) return;

        final currentPage =
            (_suggestedPlaylistsController.page ?? 0).round();
        final nextPage = (currentPage + 1) % _suggestedItemCount;

        _suggestedPlaylistsController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  void _pauseSuggestedAutoScroll({Duration resumeDelay = Duration.zero}) {
    _suggestedAutoPaused = true;
    _suggestedResumeTimer?.cancel();
    if (resumeDelay == Duration.zero) return;

    _suggestedResumeTimer = Timer(resumeDelay, () {
      _suggestedAutoPaused = false;
    });
  }

  Widget _buildRecommendedSongsSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: externalRecommendations,
      builder: (_, recommendations, __) {
        return AsyncLoader<List<dynamic>>(
          future: getRecommendedSongs(),

          builder: (context, data) {
            if (data.isEmpty) return const SizedBox.shrink();
            return _buildRecommendedForYouSection(context, data);
          },
        );
      },
    );
  }

  Widget _buildRecommendedForYouSection(
    BuildContext context,
    List<dynamic> data,
  ) {
    final recommendedTitle = context.l10n!.recommendedForYou;

    return Column(
      children: [
        SectionHeader(
          title: recommendedTitle,
          icon: FluentIcons.sparkle_24_filled,
          actionButton: IconButton(
            onPressed: () async {
              await audioHandler.playPlaylistSong(
                playlist: {'title': recommendedTitle, 'list': data},
                songIndex: 0,
              );
            },
            icon: Icon(
              FluentIcons.play_circle_24_filled,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: data.length,
          padding: commonListViewBottomPadding,
          itemBuilder: (context, index) {
            final borderRadius = getItemBorderRadius(index, data.length);
            return RepaintBoundary(
              key: ValueKey('song_${data[index]['ytid']}'),
              child: SongBar(data[index], true, borderRadius: borderRadius),
            );
          },
        ),
      ],
    );
  }
}
