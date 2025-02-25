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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/announcement_box.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/section_header.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  url: _url,
                );
              },
            ),
            _buildSuggestedPlaylists(playlistHeight),
            _buildRecommendedSongsAndArtists(playlistHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(padding: EdgeInsets.all(35), child: Spinner()),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Text(
        '${context.l10n!.error}!',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaylists(double playlistHeight) {
    return FutureBuilder<List<dynamic>>(
      future: getPlaylists(playlistsNum: recommendedCubesNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        } else if (snapshot.hasError) {
          logger.log(
            'Error in _buildSuggestedPlaylists',
            snapshot.error,
            snapshot.stackTrace,
          );
          return _buildErrorWidget(context);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final playlists = snapshot.data!;
        final itemsNumber =
            playlists.length > recommendedCubesNumber
                ? recommendedCubesNumber
                : playlists.length;
        final isLargeScreen = MediaQuery.of(context).size.width > 480;

        return Column(
          children: [
            SectionHeader(title: context.l10n!.suggestedPlaylists),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: playlistHeight),
              child:
                  isLargeScreen
                      ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: itemsNumber,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: GestureDetector(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PlaylistPage(
                                            playlistId: playlist['ytid'],
                                          ),
                                    ),
                                  ),
                              child: PlaylistCube(
                                playlist,
                                size: playlistHeight,
                              ),
                            ),
                          );
                        },
                      )
                      : CarouselView.weighted(
                        flexWeights: const <int>[3, 2, 1],
                        itemSnapping: true,
                        onTap:
                            (index) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PlaylistPage(
                                      playlistId: playlists[index]['ytid'],
                                    ),
                              ),
                            ),
                        children: List.generate(itemsNumber, (index) {
                          final playlist = playlists[index];
                          return PlaylistCube(
                            playlist,
                            size: playlistHeight * 2,
                          );
                        }),
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendedSongsAndArtists(double playlistHeight) {
    return ValueListenableBuilder<bool>(
      valueListenable: defaultRecommendations,
      builder: (_, recommendations, __) {
        return FutureBuilder<dynamic>(
          future: getRecommendedSongs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            } else if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                logger.log(
                  'Error in _buildRecommendedSongsAndArtists',
                  snapshot.error,
                  snapshot.stackTrace,
                );
                return _buildErrorWidget(context);
              } else if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final data = snapshot.data as List<dynamic>;
              final itemsNumber =
                  data.length > recommendedCubesNumber
                      ? recommendedCubesNumber
                      : data.length;
              final isLargeScreen = MediaQuery.of(context).size.width > 480;

              return Column(
                children: [
                  if (!recommendations) ...[
                    SectionHeader(title: context.l10n!.suggestedArtists),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: playlistHeight),
                      child:
                          isLargeScreen
                              ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: itemsNumber,
                                itemBuilder: (context, index) {
                                  final artist =
                                      data[index]['artist'].split('~')[0];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: GestureDetector(
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => PlaylistPage(
                                                    cubeIcon:
                                                        FluentIcons
                                                            .mic_sparkle_24_regular,
                                                    playlistId: artist,
                                                    isArtist: true,
                                                  ),
                                            ),
                                          ),
                                      child: PlaylistCube(
                                        {'title': artist},
                                        cubeIcon:
                                            FluentIcons.mic_sparkle_24_regular,
                                        size: playlistHeight,
                                      ),
                                    ),
                                  );
                                },
                              )
                              : CarouselView.weighted(
                                flexWeights: const <int>[3, 2, 1],
                                itemSnapping: true,
                                onTap:
                                    (index) => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => PlaylistPage(
                                              cubeIcon:
                                                  FluentIcons
                                                      .mic_sparkle_24_regular,
                                              playlistId:
                                                  data[index]['artist'].split(
                                                    '~',
                                                  )[0],
                                              isArtist: true,
                                            ),
                                      ),
                                    ),
                                children: List.generate(itemsNumber, (index) {
                                  final artist =
                                      data[index]['artist'].split('~')[0];
                                  return PlaylistCube(
                                    {'title': artist},
                                    cubeIcon:
                                        FluentIcons.mic_sparkle_24_regular,
                                    size: playlistHeight * 2,
                                  );
                                }),
                              ),
                    ),
                  ],
                  _buildRecommendedForYouSection(context, data),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Widget _buildRecommendedForYouSection(
    BuildContext context,
    List<dynamic> data,
  ) {
    return Column(
      children: [
        SectionHeader(
          title: context.l10n!.recommendedForYou,
          actionButton: IconButton(
            onPressed: () {
              setActivePlaylist({
                'title': context.l10n!.recommendedForYou,
                'list': data,
              });
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
          padding: commonListViewBottmomPadding,
          itemBuilder: (context, index) {
            final borderRadius = getItemBorderRadius(index, data.length);
            return SongBar(data[index], true, borderRadius: borderRadius);
          },
        ),
      ],
    );
  }
}
