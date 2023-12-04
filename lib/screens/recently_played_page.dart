import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';

import 'package:musify/widgets/song_bar.dart';

class RecentlyPlayed extends StatefulWidget {
  const RecentlyPlayed({super.key});

  @override
  State<RecentlyPlayed> createState() => _RecentlyPlayedState();
}

class _RecentlyPlayedState extends State<RecentlyPlayed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n!.recentlyPlayed,
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: currentRecentlyPlayedLength,
        builder: (_, value, __) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: userRecentlyPlayed.length,
            itemBuilder: (BuildContext context, int index) {
              return SongBar(
                key: UniqueKey(),
                userRecentlyPlayed[(userRecentlyPlayed.length - 1) - index],
                true,
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(height: 15);
            },
          );
        },
      ),
    );
  }
}
