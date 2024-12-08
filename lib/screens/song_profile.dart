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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/widgets/custom_bar.dart';


class SongProfile extends StatelessWidget {
  const SongProfile({super.key});

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify the Song Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSongProfileSetting(
            'volume',
            FluentIcons.speaker_1_24_regular,
            context,
            () => {
              
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSongProfileSetting(String name, IconData icon, BuildContext context, VoidCallback onTap) {
    return CustomBar(
      context.l10n!.volumeSongProfile,
      icon,
      onTap: () => {
        
      },
    );
  }
}
