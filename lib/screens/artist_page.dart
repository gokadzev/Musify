import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/artist_cube.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class ArtistPage extends StatelessWidget {
  const ArtistPage({super.key, required this.playlist});

  final dynamic playlist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist['title']),
      ),
      body: SingleChildScrollView(
        child: playlist != null
            ? Column(
                children: <Widget>[
                  ArtistCube(playlist['title']),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      playlist['title'].toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: buildPlayButton(context),
                  ),
                  FutureBuilder(
                    future: fetchSongsList(playlist['title'].toString()),
                    builder: (context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
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
                              '${context.l10n!.nothingFound}!',
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
                ],
              )
            : SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: const Spinner(),
              ),
      ),
    );
  }

  Widget buildPlayButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setActivePlaylist(playlist);
        showToast(
          context,
          context.l10n!.queueInitText,
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
