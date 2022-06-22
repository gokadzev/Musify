import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/playlistsPage.dart';

class UserPlaylistsPage extends StatefulWidget {
  @override
  State<UserPlaylistsPage> createState() => _UserPlaylistsPageState();
}

class _UserPlaylistsPageState extends State<UserPlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
        centerTitle: true,
        title: Text(
          "User Playlists",
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              var id;
              return AlertDialog(
                backgroundColor: accent,
                content: Stack(
                  children: <Widget>[
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Youtube Playlist ID',
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
                    child: const Text(
                      'ADD',
                      style: TextStyle(color: Colors.black),
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
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const Padding(padding: EdgeInsets.only(top: 20)),
            FutureBuilder(
              future: getUserPlaylists(),
              builder: (context, data) {
                return (data as dynamic).data != null
                    ? Container(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          shrinkWrap: true,
                          physics: const ScrollPhysics(),
                          itemCount: (data as dynamic).data.length,
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            top: 16.0,
                            bottom: 20,
                          ),
                          itemBuilder: (BuildContext context, index) {
                            return Center(
                              child: GestureDetector(
                                onLongPress: () {
                                  removeUserPlaylist(
                                    (data as dynamic).data[index]["ytid"],
                                  );
                                  setState(() {});
                                },
                                child: GetPlaylist(
                                  index: index,
                                  image: (data as dynamic).data[index]["image"],
                                  title: (data as dynamic)
                                      .data[index]["title"]
                                      .toString(),
                                  id: (data as dynamic).data[index]["ytid"],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Spinner();
              },
            ),
          ],
        ),
      ),
    );
  }
}
