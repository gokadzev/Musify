import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/style/appTheme.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

List searchHistory = Hive.box('user').get('searchHistory', defaultValue: []);

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchBar = TextEditingController();
  final ValueNotifier<bool> _fetchingSongs = ValueNotifier(false);
  final FocusNode _inputNode = FocusNode();
  String _searchQuery = '';

  Future<void> search() async {
    _searchQuery = _searchBar.text;
    if (_searchQuery.isNotEmpty) {
      _fetchingSongs.value = true;
      if (!searchHistory.contains(_searchQuery)) {
        searchHistory.insert(0, _searchQuery);
        addOrUpdateData('user', 'searchHistory', searchHistory);
      }
      _fetchingSongs.value = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.search,
          style: TextStyle(
            color: accent,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 20,
                left: 12,
                right: 12,
              ),
              child: TextField(
                onSubmitted: (String value) {
                  search();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                controller: _searchBar,
                focusNode: _inputNode,
                style: TextStyle(
                  fontSize: 16,
                  color: accent,
                ),
                cursorColor: Colors.green[50],
                decoration: InputDecoration(
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(100),
                    ),
                    borderSide: BorderSide(
                      color: Theme.of(context).backgroundColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(100),
                    ),
                    borderSide: BorderSide(color: accent),
                  ),
                  suffixIcon: ValueListenableBuilder<bool>(
                    valueListenable: _fetchingSongs,
                    builder: (_, value, __) {
                      if (value == true) {
                        return IconButton(
                          icon: const SizedBox(
                            height: 18,
                            width: 18,
                            child: Spinner(),
                          ),
                          color: accent,
                          onPressed: () {
                            search();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                        );
                      } else {
                        return IconButton(
                          icon: Icon(
                            Icons.search,
                            color: accent,
                          ),
                          color: accent,
                          onPressed: () {
                            search();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                        );
                      }
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
            ),
            if (_searchQuery.isEmpty)
              ListView.builder(
                shrinkWrap: true,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searchHistory.length,
                itemBuilder: (BuildContext ctxt, int index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Card(
                      child: ListTile(
                        leading: Icon(Icons.search, color: accent),
                        title: Text(
                          searchHistory[index],
                          style: TextStyle(color: accent),
                        ),
                        onTap: () async {
                          _fetchingSongs.value = true;
                          _searchQuery = searchHistory[index];
                          await fetchSongsList(searchHistory[index]);
                          _fetchingSongs.value = false;
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
              )
            else
              FutureBuilder(
                future: fetchSongsList(_searchQuery),
                builder: (context, data) {
                  return (data as dynamic).data != null
                      ? ListView.builder(
                          shrinkWrap: true,
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: false,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: (data as dynamic).data.length,
                          itemBuilder: (BuildContext ctxt, int index) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child: SongBar(
                                (data as dynamic).data[index],
                                false,
                              ),
                            );
                          },
                        )
                      : const Spinner();
                },
              )
          ],
        ),
      ),
    );
  }
}
