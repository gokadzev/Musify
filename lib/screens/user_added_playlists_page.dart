import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/spinner.dart';

class UserPlaylistsPage extends StatefulWidget {
  @override
  State<UserPlaylistsPage> createState() => _UserPlaylistsPageState();
}

class _UserPlaylistsPageState extends State<UserPlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n!.userPlaylists,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              var id = '';
              var customPlaylistName = '';
              String? imageUrl;
              var description = '';

              return AlertDialog(
                backgroundColor:
                    Theme.of(context).dialogBackgroundColor.withOpacity(0.5),
                content: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Text(
                        context.l10n!.customPlaylistAddInstruction,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          labelText: context.l10n!.youtubePlaylistID,
                        ),
                        onChanged: (value) {
                          id = value;
                        },
                      ),
                      const SizedBox(height: 7),
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
                      const SizedBox(height: 7),
                      TextField(
                        decoration: InputDecoration(
                          labelText: context.l10n!.customPlaylistDesc,
                        ),
                        onChanged: (value) {
                          description = value;
                        },
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      context.l10n!.add.toUpperCase(),
                    ),
                    onPressed: () {
                      if (id.isNotEmpty) {
                        showToast(context, addUserPlaylist(id, context));
                      } else if (customPlaylistName.isNotEmpty) {
                        showToast(
                          context,
                          createCustomPlaylist(
                            customPlaylistName,
                            imageUrl,
                            description,
                            context,
                          ),
                        );
                      } else {
                        showToast(
                          context,
                          '${context.l10n!.provideIdOrNameError}.',
                        );
                      }

                      setState(() {
                        Navigator.pop(context);
                      });
                    },
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: colorScheme.primary,
        child: const Icon(
          FluentIcons.add_24_filled,
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const Padding(padding: EdgeInsets.only(top: 20)),
            FutureBuilder(
              future: getUserPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Spinner();
                } else if (snapshot.hasError) {
                  logger
                      .log('Error on user playlists page:  ${snapshot.error}');
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  itemBuilder: (BuildContext context, index) {
                    final playlist = _playlists[index];
                    final ytid = playlist['ytid'];

                    return GestureDetector(
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(context.l10n!.confirmation),
                              content: Text(
                                context.l10n!.removePlaylistQuestion,
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text(context.l10n!.cancel),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text(context.l10n!.remove),
                                  onPressed: () {
                                    Navigator.of(context).pop();

                                    if (ytid == null && playlist['isCustom']) {
                                      removeUserCustomPlaylist(playlist);
                                    } else {
                                      removeUserPlaylist(ytid);
                                    }

                                    setState(() {});
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: PlaylistCube(
                        id: ytid,
                        image: playlist['image'],
                        title: playlist['title'].toString(),
                        playlistData:
                            playlist['isCustom'] != null && playlist['isCustom']
                                ? playlist
                                : null,
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
}
