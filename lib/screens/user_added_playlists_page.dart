import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
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
          context.l10n()!.userPlaylists,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              var id = '';
              var customPlaylistName = '';
              var imageUrl = '';
              var description = '';

              return AlertDialog(
                backgroundColor:
                    Theme.of(context).dialogBackgroundColor.withOpacity(0.5),
                content: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Text(
                        context.l10n()!.customPlaylistAddInstruction,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          hintText: context.l10n()!.youtubePlaylistID,
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                        ),
                        onChanged: (value) {
                          setState(() {
                            id = value;
                          });
                        },
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        decoration: InputDecoration(
                          hintText: context.l10n()!.customPlaylistName,
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                        ),
                        onChanged: (value) {
                          setState(() {
                            customPlaylistName = value;
                          });
                        },
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        decoration: InputDecoration(
                          hintText: context.l10n()!.customPlaylistImgUrl,
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                        ),
                        onChanged: (value) {
                          setState(() {
                            imageUrl = value;
                          });
                        },
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        decoration: InputDecoration(
                          hintText: context.l10n()!.customPlaylistDesc,
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                        ),
                        onChanged: (value) {
                          setState(() {
                            description = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      context.l10n()!.add.toUpperCase(),
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
                          '${context.l10n()!.provideIdOrNameError}.',
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
              builder: (context, data) {
                return (data as dynamic).data != null
                    ? GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        shrinkWrap: true,
                        physics: const ScrollPhysics(),
                        itemCount: (data as dynamic).data.length as int,
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 20,
                        ),
                        itemBuilder: (BuildContext context, index) {
                          return Center(
                            child: GestureDetector(
                              onLongPress: () {
                                removeUserPlaylist(
                                  (data as dynamic)
                                      .data[index]['ytid']
                                      .toString(),
                                );
                                setState(() {});
                              },
                              child: PlaylistCube(
                                id: (data as dynamic).data[index]['ytid'],
                                image: (data as dynamic).data[index]['image'],
                                title: (data as dynamic)
                                    .data[index]['title']
                                    .toString(),
                                playlistData: (data as dynamic).data[index]
                                        ['isCustom']
                                    ? (data as dynamic).data[index]
                                    : null,
                              ),
                            ),
                          );
                        },
                      )
                    : const Spinner();
              },
            ),
          ],
        ),
      ),
    );
  }
}
