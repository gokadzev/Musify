import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/playlistsPage.dart';

class UserPlaylistsPage extends StatefulWidget {
  const UserPlaylistsPage({Key? key}) : super(key: key);

  @override
  State<UserPlaylistsPage> createState() => _UserPlaylistsPageState();
}

class _UserPlaylistsPageState extends State<UserPlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.userPlaylists,
          style: TextStyle(
            color: accent,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: accent,
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String id = '';
              return AlertDialog(
                backgroundColor: accent,
                content: Stack(
                  children: <Widget>[
                    TextField(
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)!.youtubePlaylistID,
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
                      style: const TextStyle(color: Colors.black),
                    ),
                    onPressed: () {
                      addUserPlaylist(id);
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
        backgroundColor: accent,
        child: Icon(
          Icons.add,
          color:
              accent != const Color(0xFFFFFFFF) ? Colors.white : Colors.black,
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
                              child: GetPlaylist(
                                index: index,
                                image: (data as dynamic).data[index]['image'],
                                title: (data as dynamic)
                                    .data[index]['title']
                                    .toString(),
                                id: (data as dynamic).data[index]['ytid'],
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
