import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/style/appTheme.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

List searchHistory = Hive.box('user').get('searchHistory', defaultValue: []);
List suggestionsList = [];

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchBar = TextEditingController();
  final ValueNotifier<bool> _fetchingSongs = ValueNotifier(false);
  final FocusNode _inputNode = FocusNode();
  String _searchQuery = '';

  Future<void> search() async {
    _searchQuery = _searchBar.text;
    if (_searchQuery.isNotEmpty) {
      if (_fetchingSongs.value != true) _fetchingSongs.value = true;
      if (!searchHistory.contains(_searchQuery)) {
        searchHistory.insert(0, _searchQuery);
        addOrUpdateData('user', 'searchHistory', searchHistory);
      }
      if (_fetchingSongs.value != false) _fetchingSongs.value = false;
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
            color: accent.primary,
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
                  suggestionsList = [];
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                onChanged: (value) {
                  setState(() {
                    if (value != '') {
                      getSearchSuggestions(value)
                          .then((value) => suggestionsList = value);
                    } else {
                      suggestionsList = [];
                    }
                  });
                },
                textInputAction: TextInputAction.search,
                controller: _searchBar,
                focusNode: _inputNode,
                style: TextStyle(
                  fontSize: 16,
                  color: accent.primary,
                ),
                cursorColor: Colors.green[50],
                decoration: InputDecoration(
                  filled: true,
                  isDense: true,
                  fillColor: Theme.of(context).shadowColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.background,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.background,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(15),
                    ),
                    borderSide: BorderSide(color: accent.primary),
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
                          color: accent.primary,
                          onPressed: () {
                            search();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                        );
                      } else {
                        return IconButton(
                          icon: Icon(
                            FluentIcons.search_20_regular,
                            color: accent.primary,
                          ),
                          color: accent.primary,
                          onPressed: () {
                            search();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                        );
                      }
                    },
                  ),
                  hintText: '${AppLocalizations.of(context)!.search}...',
                  hintStyle: TextStyle(
                    color: accent.primary,
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
                itemCount: suggestionsList.isEmpty
                    ? searchHistory.length
                    : suggestionsList.length,
                itemBuilder: (BuildContext ctxt, int index) {
                  final suggestionsNotAvailable = suggestionsList.isEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Card(
                      child: ListTile(
                        leading: Icon(
                          FluentIcons.search_24_regular,
                          color: accent.primary,
                        ),
                        title: Text(
                          suggestionsNotAvailable
                              ? searchHistory[index]
                              : suggestionsList[index],
                          style: TextStyle(color: accent.primary),
                        ),
                        onTap: () async {
                          _fetchingSongs.value = true;
                          _searchQuery = suggestionsNotAvailable
                              ? searchHistory[index]
                              : suggestionsList[index];
                          await fetchSongsList(
                            suggestionsNotAvailable
                                ? searchHistory[index]
                                : suggestionsList[index],
                          );
                          _fetchingSongs.value = false;
                          await search();
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
                                true,
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
