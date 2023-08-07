import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/models/custom_audio_model.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalMusicBar extends StatelessWidget {
  LocalMusicBar(this.index, this.music);

  final AudioModelWithArtwork music;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        playLocalSong(index);
      },
      leading: buildArtworkWidget(),
      title: Text(
        music.displayNameWOExt,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Text(
        formatDuration(music.duration!),
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      splashColor: colorScheme.primary.withOpacity(0.4),
      hoverColor: colorScheme.primary.withOpacity(0.4),
      focusColor: colorScheme.primary.withOpacity(0.4),
    );
  }

  Widget buildArtworkWidget() {
    return QueryArtworkWidget(
      id: music.id,
      type: ArtworkType.AUDIO,
      artworkWidth: 60,
      artworkHeight: 60,
      artworkBorder: BorderRadius.circular(8),
      nullArtworkWidget: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 60,
          height: 60,
          color: colorScheme.secondary,
          child: const Icon(
            FluentIcons.music_note_1_24_regular,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
