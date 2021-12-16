import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchBar = TextEditingController();
  bool fetchingSongs = false;

  search() async {
    String searchQuery = searchBar.text;
    if (searchQuery.isEmpty) return;
    fetchingSongs = true;
    setState(() {});
    await fetchSongsList(searchQuery);
    fetchingSongs = false;
    setState(() {});
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
                              playSong(searchedList[index], context);
                            },
                            onLongPress: () {
                              getTop50();
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
                                        downloadSong(searchedList[index]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container()
          ],
        ),
      ),
    );
  }
}
