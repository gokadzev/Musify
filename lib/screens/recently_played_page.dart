import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';

import 'package:musify/widgets/song_bar.dart';

class RecentlyPlayed extends StatelessWidget {
  const RecentlyPlayed({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n!.recentlyPlayed,
        ),
      ),
      body: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: userRecentlyPlayed.length,
        itemBuilder: (BuildContext context, int index) {
          return SongBar(
            userRecentlyPlayed[(userRecentlyPlayed.length - 1) - index],
            true,
          );
        },
      ),
    );
  }
}
