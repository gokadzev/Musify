import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/widgets/custom_search_bar.dart';
import 'package:musify/widgets/song_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

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
    } catch (e, stackTrace) {
      logger.log('Error while searching online songs', e, stackTrace);
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
            CustomSearchBar(
              loadingProgressNotifier: _fetchingSongs,
              controller: _searchBar,
              focusNode: _inputNode,
              labelText: '${context.l10n!.search}...',
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  _suggestionsList = await getSearchSuggestions(value);
                } else {
                  _suggestionsList = [];
                }
                setState(() {});
              },
              onSubmitted: (String value) {
                search();
                _suggestionsList = [];
                _inputNode.unfocus();
              },
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

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: Icon(
                        FluentIcons.search_24_regular,
                        color: Theme.of(context).colorScheme.primary,
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
                  );
                },
              )
            else
              ListView.builder(
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
