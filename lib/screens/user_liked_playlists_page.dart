/*
 *     Copyright (C) 2024 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/widgets/playlist_cube.dart';

class UserLikedPlaylistsPage extends StatelessWidget {
  const UserLikedPlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.likedPlaylists),
      ),
      body: ValueListenableBuilder(
        valueListenable: currentLikedPlaylistsLength,
        builder: (_, value, __) {
          return userLikedPlaylists.isEmpty
              ? Center(
                  child: Text(
                    context.l10n!.noLikedPlaylists,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    shrinkWrap: true,
                    physics: const ScrollPhysics(),
                    itemCount: userLikedPlaylists.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (BuildContext context, index) {
                      return PlaylistCube(userLikedPlaylists[index]);
                    },
                  ),
                );
        },
      ),
    );
  }
}
