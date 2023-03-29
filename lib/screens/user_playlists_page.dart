import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
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
          AppLocalizations.of(context)!.userPlaylists,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              var id = '';
              return AlertDialog(
                backgroundColor:
                    Theme.of(context).dialogBackgroundColor.withOpacity(0.5),
                content: Stack(
                  children: <Widget>[
                    TextField(
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)!.youtubePlaylistID,
                        hintStyle:
                            TextStyle(color: Theme.of(context).hintColor),
                      ),
                      onChanged: (value) {
                        setState(() {
                          id = value;
                        });
                      },
                    )
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      AppLocalizations.of(context)!.add.toUpperCase(),
                    ),
                    onPressed: () {
                      showToast(addUserPlaylist(id, context));
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
        child: Icon(
          FluentIcons.add_24_filled,
          color: Theme.of(context).textTheme.bodyMedium!.color,
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
