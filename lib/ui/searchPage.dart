import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/style/appColors.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchBar = TextEditingController();
  bool fetchingSongs = false;
  FocusNode inputNode = FocusNode();

  Future<void> search() async {
    final String searchQuery = searchBar.text;
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.search,
          style: TextStyle(
            color: accent,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            const Padding(padding: EdgeInsets.only(bottom: 20.0)),
            TextField(
              onSubmitted: (String value) {
                search();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              controller: searchBar,
              focusNode: inputNode,
              style: TextStyle(
                fontSize: 16,
                color: accent,
              ),
              cursorColor: Colors.green[50],
              decoration: InputDecoration(
                fillColor: bgLight,
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
                  borderRadius: const BorderRadius.all(
                    Radius.circular(100),
                  ),
                  borderSide: BorderSide(color: accent),
                ),
                suffixIcon: IconButton(
                  icon: fetchingSongs
                      ? SizedBox(height: 18, width: 18, child: Spinner())
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
                hintText: '${AppLocalizations.of(context)!.search}...',
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
            if (searchedList.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searchedList.length,
                itemBuilder: (BuildContext ctxt, int index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: SongBar(searchedList[index]),
                  );
                },
              )
          ],
        ),
      ),
    );
  }
}
