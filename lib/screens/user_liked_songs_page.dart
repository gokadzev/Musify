import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/style/app_colors.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/song_bar.dart';

class UserLikedSongs extends StatefulWidget {
  const UserLikedSongs({super.key});

  @override
  State<UserLikedSongs> createState() => _UserLikedSongsState();
}

class _UserLikedSongsState extends State<UserLikedSongs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.userLikedSongs,
          style: TextStyle(
            color: accent.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10),
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
                            FluentIcons.music_note_1_24_regular,
                            size: 30,
                            color: accent.primary,
                          ),
                          Text(
                            AppLocalizations.of(context)!.userLikedSongs,
                            style: TextStyle(color: accent.primary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.userLikedSongs,
                        style: TextStyle(
                          color: accent.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${AppLocalizations.of(context)!.yourFavoriteSongsHere}!',
                        style: TextStyle(
                          color: accent.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 5, bottom: 5),
                      ),
                      ElevatedButton(
                        onPressed: () => {
                          setActivePlaylist(
                            {
                              'ytid': '',
                              'title':
                                  AppLocalizations.of(context)!.userLikedSongs,
                              'subtitle': 'Just Updated',
                              'header_desc': '',
                              'type': 'playlist',
                              'image': '',
                              'list': userLikedSongsList
                            },
                          ),
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(accent.primary),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.playAll.toUpperCase(),
                          style: TextStyle(
                            color: isAccentWhite(),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const Padding(padding: EdgeInsets.only(top: 20)),
            ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
              itemCount: userLikedSongsList.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  child: SongBar(
                    userLikedSongsList[index],
                    true,
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
