/*
 *     Copyright (C) 2024 Valeri Gokadze
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
import 'package:musify/screens/device_songs_page.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/spinner.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class UserPlaylistsPage extends StatefulWidget {
  const UserPlaylistsPage({super.key});

  @override
  State<UserPlaylistsPage> createState() => _UserPlaylistsPageState();
}

class _UserPlaylistsPageState extends State<UserPlaylistsPage> {
  late Future<List> _playlistsFuture;
  bool isYouTubeMode = true;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = getUserPlaylists();
  }

  Future<void> _refreshPlaylists() async {
    setState(() {
      _playlistsFuture = getUserPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('IN EDIT THIS PAGE--------------------------------');

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.userPlaylists),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              var id = '';
              var customPlaylistName = '';
              String? imageUrl;

              return StatefulBuilder(
                builder: (context, setState) {
                  final activeButtonBackground =
                      Theme.of(context).colorScheme.surfaceContainer;
                  final inactiveButtonBackground =
                      Theme.of(context).colorScheme.secondaryContainer;
                  return AlertDialog(
                    backgroundColor: Theme.of(context).dialogBackgroundColor,
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isYouTubeMode = true;
                                    id = '';
                                    customPlaylistName = '';
                                    imageUrl = null;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isYouTubeMode
                                      ? inactiveButtonBackground
                                      : activeButtonBackground,
                                ),
                                child:
                                    const Icon(FluentIcons.globe_add_24_filled),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isYouTubeMode = false;
                                    id = '';
                                    customPlaylistName = '';
                                    imageUrl = null;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isYouTubeMode
                                      ? activeButtonBackground
                                      : inactiveButtonBackground,
                                ),
                                child: const Icon(
                                  FluentIcons.person_add_24_filled,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (isYouTubeMode)
                            TextField(
                              decoration: InputDecoration(
                                labelText:
                                    context.l10n!.youtubePlaylistLinkOrId,
                              ),
                              onChanged: (value) {
                                id = value;
                              },
                            )
                          else ...[
                            TextField(
                              decoration: InputDecoration(
                                labelText: context.l10n!.customPlaylistName,
                              ),
                              onChanged: (value) {
                                customPlaylistName = value;
                              },
                            ),
                            const SizedBox(height: 7),
                            TextField(
                              decoration: InputDecoration(
                                labelText: context.l10n!.customPlaylistImgUrl,
                              ),
                              onChanged: (value) {
                                imageUrl = value;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text(
                          context.l10n!.add.toUpperCase(),
                        ),
                        onPressed: () async {
                          if (isYouTubeMode && id.isNotEmpty) {
                            showToast(
                              context,
                              await addUserPlaylist(id, context),
                            );
                          } else if (!isYouTubeMode &&
                              customPlaylistName.isNotEmpty) {
                            showToast(
                              context,
                              createCustomPlaylist(
                                customPlaylistName,
                                imageUrl,
                                context,
                              ),
                            );
                          } else {
                            showToast(
                              context,
                              '${context.l10n!.provideIdOrNameError}.',
                            );
                          }

                          Navigator.pop(context);
                          await _refreshPlaylists();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        child: const Icon(FluentIcons.add_24_filled),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 15),
        child: Column(
          children: [
            _buildSuggestedPlaylists(),
            SizedBox(
              width: 200,
              height: 200,
              child: ElevatedButton(
                onPressed: () => _checkPermissionAndScanDevice(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                child: const Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Center(child: Text('ON Device')),
                  ],
                ),
              ),
            ),
            FutureBuilder(
              future: _playlistsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Spinner();
                } else if (snapshot.hasError) {
                  logger.log(
                    'Error on user playlists page',
                    snapshot.error,
                    snapshot.stackTrace,
                  );
                  return Center(
                    child: Text(context.l10n!.error),
                  );
                }

                final _playlists = snapshot.data as List;

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemCount: _playlists.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (BuildContext context, index) {
                    final playlist = _playlists[index];
                    final ytid = playlist['ytid'];

                    return GestureDetector(
                      onTap: playlist['isCustom'] ?? false
                          ? () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PlaylistPage(playlistData: playlist),
                                ),
                              );
                              if (result == false) {
                                setState(() {});
                              }
                            }
                          : null,
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return ConfirmationDialog(
                              confirmationMessage:
                                  context.l10n!.removePlaylistQuestion,
                              submitMessage: context.l10n!.remove,
                              onCancel: () {
                                Navigator.of(context).pop();
                              },
                              onSubmit: () {
                                Navigator.of(context).pop();

                                if (ytid == null && playlist['isCustom']) {
                                  removeUserCustomPlaylist(playlist);
                                } else {
                                  removeUserPlaylist(ytid);
                                }

                                _refreshPlaylists();
                              },
                            );
                          },
                        );
                      },
                      child: PlaylistCube(
                        playlist,
                        playlistData:
                            playlist['isCustom'] ?? false ? playlist : null,
                        onClickOpen: playlist['isCustom'] == null,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnDeviceButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _checkPermissionAndScanDevice(context),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        padding: const EdgeInsets.all(16), // Padding inside the button
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ), // Margin around the button
        child: Stack(
          alignment: Alignment.bottomRight, // Align the like button
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  FluentIcons.music_note_2_24_regular,
                  size: 48,
                ), // Example icon
                const SizedBox(height: 8),
                Text(
                  'ON Device',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                FluentIcons.heart_24_filled,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                // Handle like action here
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(35),
        child: Spinner(),
      ),
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

  Widget _buildSuggestedPlaylists() {
    return FutureBuilder<List<dynamic>>(
      future: getPlaylists(playlistsNum: 5),
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

        return _buildPlaylistSection(context, snapshot.data!);
      },
    );
  }

  Widget _buildPlaylistSection(BuildContext context, List<dynamic> playlists) {
    final playlistHeight = MediaQuery.sizeOf(context).height * 0.25 / 1.1;

    return Column(
      children: [
        _buildSectionHeader(
          title: context.l10n!.suggestedPlaylists,
          actionButton: IconButton(
            onPressed: () => NavigationManager.router.go('/home/playlists'),
            icon: Icon(
              FluentIcons.more_horizontal_24_regular,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          height: playlistHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 15),
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return PlaylistCube(
                playlist,
                isAlbum: playlist['isAlbum'],
                size: playlistHeight,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, Widget? actionButton}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.7,
            child: MarqueeWidget(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (actionButton != null) actionButton,
        ],
      ),
    );
  }

// Create an instance of OnAudioQuery
  final OnAudioQuery audioQuery = OnAudioQuery();

  Future<void> _checkPermissionAndScanDevice(BuildContext context) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      final songs = await audioQuery.querySongs();
      if (songs.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DeviceSongsPage(),
          ),
        );
      } else {
        showToast(context, 'No songs found on the device');
      }
    } else {
      showToast(context, 'Storage permission denied');
    }
  }

  void _showDeviceSongsDialog(BuildContext context, List<SongModel> songs) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Device Songs'),
          content: SizedBox(
            height: 400,
            width: 300,
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(songs[index].title),
                  subtitle: Text(songs[index].artist ?? 'Unknown artist'),
                  onTap: () {
                    // Handle song click, e.g., play the song
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
