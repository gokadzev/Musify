import 'dart:io';

import 'package:Musify/API/musify.dart';
import 'package:Musify/services/ext_storage.dart';
import 'package:Musify/style/appColors.dart';
import 'package:audiotagger/audiotagger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:Musify/music.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchBar = TextEditingController();
  bool fetchingSongs = false;

  downloadSong(id) async {
    String filepath;
    String filepath2;
    var status = await Permission.storage.status;
    if (status.isDenied) {
      // code of read or write file in external storage (SD card)
      // You can request multiple permissions at once.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      debugPrint(statuses[Permission.storage].toString());
    }
    status = await Permission.storage.status;
    await fetchSongDetails(id);
    if (status.isGranted) {
      ProgressDialog pr = ProgressDialog(context);
      pr = ProgressDialog(
        context,
        type: ProgressDialogType.Normal,
        isDismissible: false,
        showLogs: false,
      );

      pr.style(
        backgroundColor: Color(0xff263238),
        elevation: 4,
        textAlign: TextAlign.left,
        progressTextStyle: TextStyle(color: Colors.white),
        message: "Downloading " + title,
        messageTextStyle: TextStyle(color: accent),
        progressWidget: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      );
      await pr.show();

      final filename = title + ".mp3";
      final artname = title + "_artwork.jpg";
      //Directory appDocDir = await getExternalStorageDirectory();
      String dlPath = await ExtStorageProvider.getExtStorage(dirName: 'Music');
      await File(dlPath + "/" + filename)
          .create(recursive: true)
          .then((value) => filepath = value.path);
      await File(dlPath + "/" + artname)
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
      debugPrint('Audio path $filepath');
      debugPrint('Image path $filepath2');
      var request = await HttpClient().getUrl(Uri.parse(kUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      File file = File(filepath);

      var request2 = await HttpClient().getUrl(Uri.parse(image));
      var response2 = await request2.close();
      var bytes2 = await consolidateHttpClientResponseBytes(response2);
      File file2 = File(filepath2);

      await file.writeAsBytes(bytes);
      await file2.writeAsBytes(bytes2);
      debugPrint("Started tag editing");

      final tag = Tag(
        title: title,
        artist: artist,
        artwork: filepath2,
        album: album,
        lyrics: lyrics,
        genre: null,
      );

      debugPrint("Setting up Tags");
      final tagger = Audiotagger();
      await tagger.writeTags(
        path: filepath,
        tag: tag,
      );
      await Future.delayed(const Duration(seconds: 1), () {});
      await pr.hide();

      if (await file2.exists()) {
        await file2.delete();
      }
      debugPrint("Done");
      Fluttertoast.showToast(
          msg: "Download Complete!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Color(0xff61e88a),
          fontSize: 14.0);
    } else if (status.isDenied || status.isPermanentlyDenied) {
      Fluttertoast.showToast(
          msg: "Storage Permission Denied!\nCan't Download Songs",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Color(0xff61e88a),
          fontSize: 14.0);
    } else {
      Fluttertoast.showToast(
          msg: "Permission Error!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.values[50],
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Color(0xff61e88a),
          fontSize: 14.0);
    }
  }

  search() async {
    String searchQuery = searchBar.text;
    if (searchQuery.isEmpty) return;
    fetchingSongs = true;
    setState(() {});
    await fetchSongsList(searchQuery);
    fetchingSongs = false;
    setState(() {});
  }

  getSongDetails(int id, var context) async {
    try {
      await fetchSongDetails(id);
    } catch (e) {
      artist = "Unknown";
    }
    setState(() {
      checker = "Haa";
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioApp(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 30, bottom: 20.0)),
            TextField(
              onSubmitted: (String value) {
                search();
              },
              controller: searchBar,
              style: TextStyle(
                fontSize: 16,
                color: accent,
              ),
              cursorColor: Colors.green[50],
              decoration: InputDecoration(
                fillColor: Color(0xff263238),
                filled: true,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(100),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xff263238),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(100),
                  ),
                  borderSide: BorderSide(color: accent),
                ),
                suffixIcon: IconButton(
                  icon: fetchingSongs
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.search,
                          color: accent,
                        ),
                  color: accent,
                  onPressed: () {
                    search();
                  },
                ),
                border: InputBorder.none,
                hintText: "Search...",
                hintStyle: TextStyle(
                  color: accent,
                ),
                contentPadding: const EdgeInsets.only(
                  left: 18,
                  right: 20,
                  top: 14,
                  bottom: 14,
                ),
              ),
            ),
            searchedList.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: searchedList.length,
                    itemBuilder: (BuildContext ctxt, int index) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 5),
                        child: Card(
                          color: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10.0),
                            onTap: () {
                              getSongDetails(
                                  searchedList[index]["id"], context);
                            },
                            onLongPress: () {
                              topSongs();
                            },
                            splashColor: accent,
                            hoverColor: accent,
                            focusColor: accent,
                            highlightColor: accent,
                            child: Column(
                              children: <Widget>[
                                ListTile(
                                  leading: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      MdiIcons.musicNoteOutline,
                                      size: 30,
                                      color: accent,
                                    ),
                                  ),
                                  title: Text(
                                    (searchedList[index]['title'])
                                        .toString()
                                        .split("(")[0]
                                        .replaceAll("&quot;", "\"")
                                        .replaceAll("&amp;", "&"),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    searchedList[index]['more_info']["singers"],
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  trailing: IconButton(
                                    color: accent,
                                    icon: Icon(MdiIcons.downloadOutline),
                                    onPressed: () =>
                                        downloadSong(searchedList[index]["id"]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : FutureBuilder(
                    future: topSongs(),
                    builder: (context, data) {
                      return Center(
                          child: Padding(
                        padding: const EdgeInsets.all(35.0),
                      ));
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
