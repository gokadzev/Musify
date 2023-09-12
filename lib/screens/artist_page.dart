import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/services/offline_audio.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/artist_cube.dart';
import 'package:musify/widgets/local_music_bar.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({super.key, required this.playlist});
  final dynamic playlist;

  @override
  _ArtistPagePageState createState() => _ArtistPagePageState();
}

class _ArtistPagePageState extends State<ArtistPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.playlist['title'],
        ),
      ),
      body: SingleChildScrollView(
        child: widget.playlist != null
            ? Column(
                children: [
                  ArtistCube(widget.playlist['title']),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      widget.playlist['title'].toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  buildPlayButton(),
                  MaterialBarSwitcher(
                    firstBarTitle: context.l10n()!.offlineResults,
                    secondBarTitle: context.l10n()!.onlineResults,
                    firstBarChild: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.playlist['list'].length,
                      itemBuilder: (BuildContext context, int index) {
                        return LocalMusicBar(
                          getMusicIndex(widget.playlist['list'][index]) ??
                              index,
                          widget.playlist['list'][index],
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(height: 15);
                      },
                    ),
                    secondBarChild: FutureBuilder(
                      future:
                          fetchSongsList(widget.playlist['title'].toString()),
                      builder: (context, AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(35),
                              child: Spinner(),
                            ),
                          );
                        } else if (snapshot.connectionState ==
                            ConnectionState.done) {
                          if (snapshot.hasError || snapshot.data.isEmpty) {
                            return Center(
                              child: Text(
                                'Nothing Found!',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 18,
                                ),
                              ),
                            );
                          }
                          return Wrap(
                            children: <Widget>[
                              ListView.separated(
                                shrinkWrap: true,
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: false,
                                physics: const BouncingScrollPhysics(),
                                itemCount: snapshot.data.length as int,
                                itemBuilder: (context, index) {
                                  return SongBar(snapshot.data[index], true);
                                },
                                separatorBuilder:
                                    (BuildContext context, int index) {
                                  return const SizedBox(height: 15);
                                },
                              ),
                            ],
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ],
              )
            : SizedBox(
                height: context.screenSize.height - 100,
                child: const Spinner(),
              ),
      ),
    );
  }

  Widget buildPlayButton() {
    return GestureDetector(
      onTap: () {
        setActivePlaylist(widget.playlist);
        showToast(
          context,
          context.l10n()!.queueInitText,
        );
      },
      child: Icon(
        FluentIcons.play_circle_48_filled,
        color: colorScheme.primary,
        size: 60,
      ),
    );
  }
}

class MaterialBarSwitcher extends StatefulWidget {
  const MaterialBarSwitcher({
    super.key,
    required this.firstBarTitle,
    required this.secondBarTitle,
    required this.firstBarChild,
    required this.secondBarChild,
  });
  final String firstBarTitle;
  final String secondBarTitle;
  final Widget firstBarChild;
  final Widget secondBarChild;

  @override
  _MaterialBarSwitcherState createState() => _MaterialBarSwitcherState();
}

class _MaterialBarSwitcherState extends State<MaterialBarSwitcher> {
  bool _showFirstBar = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showFirstBar = true;
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                child: Text(
                  widget.firstBarTitle,
                  style: TextStyle(
                    color: _showFirstBar ? colorScheme.primary : Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showFirstBar = false;
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                child: Text(
                  widget.secondBarTitle,
                  style: TextStyle(
                    color: _showFirstBar ? Colors.grey : colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_showFirstBar) widget.firstBarChild else widget.secondBarChild,
      ],
    );
  }
}
