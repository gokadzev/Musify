import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/models/custom_audio_model.dart';
import 'package:musify/services/offline_audio.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/local_song_bar.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/spinner.dart';

class LocalMusicPage extends StatefulWidget {
  @override
  State<LocalMusicPage> createState() => _LocalMusicPageState();
}

class _LocalMusicPageState extends State<LocalMusicPage> {
  final TextEditingController _searchBar = TextEditingController();
  final FocusNode _inputNode = FocusNode();
  String _searchQuery = '';

  Future<void> search() async {
    final newSearchQuery = _searchBar.text;
    if (_searchQuery != newSearchQuery) {
      _searchQuery = newSearchQuery;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchBar.dispose();
    _inputNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n()!.localMusic,
          style: paytoneOneStyle,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: PlaylistCube(
                  title: context.l10n()!.localMusic,
                  cubeIcon: FluentIcons.save_24_filled,
                  onClickOpen: false,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: TextField(
                onSubmitted: (_) {
                  search();
                  FocusManager.instance.primaryFocus?.unfocus();
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
                    borderRadius: const BorderRadius.all(
                      Radius.circular(15),
                    ),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      FluentIcons.search_24_regular,
                      color: colorScheme.primary,
                    ),
                    color: colorScheme.primary,
                    onPressed: () {
                      search();
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                  hintText: '${context.l10n()!.search}...',
                  hintStyle: TextStyle(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 10)),
            FutureBuilder<List<AudioModelWithArtwork>>(
              future: getMusic(searchQuery: _searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: Spinner(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      context.l10n()!.error,
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  );
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return LocalSongBar(index, snapshot.data![index]);
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
