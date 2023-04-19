import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/offline_audio.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/widgets/spinner.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalMusicPage extends StatefulWidget {
  @override
  State<LocalMusicPage> createState() => _LocalMusicPageState();
}

class _LocalMusicPageState extends State<LocalMusicPage> {
  final TextEditingController _searchBar = TextEditingController();
  final FocusNode _inputNode = FocusNode();
  String _searchQuery = '';

  Future<void> search() async {
    _searchQuery = _searchBar.text;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.localMusic,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 26),
                  height: 200,
                  width: 200,
                  child: Card(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context)
                            .colorScheme
                            .background
                            .withAlpha(30),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            FluentIcons.save_24_filled,
                            size: 30,
                            color: colorScheme.primary,
                          ),
                          Text(
                            AppLocalizations.of(context)!.localMusic,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.localMusic,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 5, bottom: 5),
                      ),
                      ElevatedButton(
                        onPressed: () async => {
                          setActivePlaylist(
                            {
                              'ytid': '',
                              'title': AppLocalizations.of(context)!.localMusic,
                              'header_desc': '',
                              'image': '',
                              'list': await getMusic()
                            },
                          ),
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            colorScheme.primary,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.playAll.toUpperCase(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
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
                  hintText: '${AppLocalizations.of(context)!.search}...',
                  hintStyle: TextStyle(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 40)),
            FutureBuilder<List<AudioModel>>(
              future: _searchQuery.isEmpty
                  ? Future.delayed(const Duration(milliseconds: 500), getMusic)
                  : Future.delayed(
                      const Duration(milliseconds: 500),
                      () => getMusic(searchQuery: _searchQuery),
                    ),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: Spinner(),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    final lsong = returnSongLayoutFromAudioModel(
                      index,
                      snapshot.data![index],
                    );

                    return Container(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 15,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          playSong(lsong);
                        },
                        splashColor: colorScheme.primary.withOpacity(0.4),
                        hoverColor: colorScheme.primary.withOpacity(0.4),
                        focusColor: colorScheme.primary.withOpacity(0.4),
                        highlightColor: colorScheme.primary.withOpacity(0.4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            QueryArtworkWidget(
                              id: lsong['localSongId'] as int,
                              type: ArtworkType.AUDIO,
                              artworkWidth: 60,
                              artworkHeight: 60,
                              artworkFit: BoxFit.cover,
                              artworkBorder: BorderRadius.circular(8),
                              keepOldArtwork: true,
                              nullArtworkWidget: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      const Icon(
                                        FluentIcons.music_note_1_24_regular,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(
                                      left: 15,
                                    ),
                                    child: Text(
                                      overflow: TextOverflow.ellipsis,
                                      lsong['artist'].toString() == ''
                                          ? lsong['title'].toString()
                                          : '${lsong['artist']} - ${lsong['title']}',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
