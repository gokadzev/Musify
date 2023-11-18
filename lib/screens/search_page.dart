import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

List searchHistory = Hive.box('user').get('searchHistory', defaultValue: []);

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchBar = TextEditingController();
  final FocusNode _inputNode = FocusNode();
  final ValueNotifier<bool> _fetchingSongs = ValueNotifier(false);
  List _searchResult = [];
  List _suggestionsList = [];

  @override
  void dispose() {
    _searchBar.dispose();
    _inputNode.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final query = _searchBar.text;

    if (query.isEmpty) {
      _searchResult = [];
      _suggestionsList = [];
      setState(() {});
      return;
    }

    if (!_fetchingSongs.value) {
      _fetchingSongs.value = true;
    }

    if (!searchHistory.contains(query)) {
      searchHistory.insert(0, query);
      addOrUpdateData('user', 'searchHistory', searchHistory);
    }

    try {
      _searchResult = await fetchSongsList(query);
    } catch (e) {
      logger.log('Error while searching online songs: $e');
    }

    if (_fetchingSongs.value) {
      _fetchingSongs.value = false;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n!.search,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: TextField(
                onSubmitted: (String value) {
                  search();
                  _suggestionsList = [];
                  _inputNode.unfocus();
                },
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    _suggestionsList = await getSearchSuggestions(value);
                  } else {
                    _suggestionsList = [];
                  }
                  setState(() {});
                },
                textInputAction: TextInputAction.search,
                controller: _searchBar,
                focusNode: _inputNode,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.primary,
                ),
                cursorColor: Colors.green[50],
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                  suffixIcon: ValueListenableBuilder<bool>(
                    valueListenable: _fetchingSongs,
                    builder: (_, value, __) {
                      if (value) {
                        return IconButton(
                          icon: const SizedBox(
                            height: 18,
                            width: 18,
                            child: Spinner(),
                          ),
                          color: colorScheme.primary,
                          onPressed: () {
                            search();
                            _inputNode.unfocus();
                          },
                        );
                      } else {
                        return IconButton(
                          icon: Icon(
                            FluentIcons.search_20_regular,
                            color: colorScheme.primary,
                          ),
                          color: colorScheme.primary,
                          onPressed: () {
                            search();
                            _inputNode.unfocus();
                          },
                        );
                      }
                    },
                  ),
                  labelText: '${context.l10n!.search}...',
                ),
              ),
            ),
            if (_searchResult.isEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestionsList.isEmpty
                    ? searchHistory.length
                    : _suggestionsList.length,
                itemBuilder: (BuildContext context, int index) {
                  final suggestionsNotAvailable = _suggestionsList.isEmpty;
                  final query = suggestionsNotAvailable
                      ? searchHistory[index]
                      : _suggestionsList[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 5,
                    ),
                    child: Card(
                      child: ListTile(
                        leading: Icon(
                          FluentIcons.search_24_regular,
                          color: colorScheme.primary,
                        ),
                        title: Text(query),
                        onTap: () async {
                          _searchBar.text = query;
                          await search();
                          _inputNode.unfocus();
                        },
                        onLongPress: () async {
                          final confirm =
                              await _showConfirmationDialog(context) ?? false;

                          if (confirm) {
                            setState(() {
                              searchHistory.remove(query);
                            });

                            addOrUpdateData(
                              'user',
                              'searchHistory',
                              searchHistory,
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResult.length,
                itemBuilder: (BuildContext context, int index) {
                  return SongBar(
                    _searchResult[index],
                    true,
                    showMusicDuration: true,
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(height: 15);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n!.confirmation),
          content: Text(context.l10n!.removeSearchQueryQuestion),
          actions: <Widget>[
            TextButton(
              child: Text(context.l10n!.cancel),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(context.l10n!.confirm),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
