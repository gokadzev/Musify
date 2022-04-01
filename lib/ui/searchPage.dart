import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/style/appColors.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchBar = TextEditingController();
  bool fetchingSongs = false;
  FocusNode inputNode = FocusNode();

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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            Padding(padding: const EdgeInsets.only(top: 30, bottom: 20.0)),
            TextField(
              onSubmitted: (String value) {
                search();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              controller: searchBar,
              focusNode: inputNode,
              autofocus: false,
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
                    FocusManager.instance.primaryFocus?.unfocus();
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
                          child: songBar(searchedList[index]));
                    },
                  )
                : Container()
          ],
        ),
      ),
    );
  }
}
