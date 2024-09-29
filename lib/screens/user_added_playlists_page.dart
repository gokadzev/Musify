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
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/spinner.dart';

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
                                labelText: context.l10n!.youtubePlaylistID,
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
        child: FutureBuilder(
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
      ),
    );
  }
}
