import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/style/app_themes.dart';

final downloadListenerNotifier = ValueNotifier<int>(0);
final lastDownloadedSongIdListener = ValueNotifier<String>('');

class DownloadButton extends StatefulWidget {
  const DownloadButton({
    super.key,
    required this.song,
  });

  final dynamic song;

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: downloadListenerNotifier,
      builder: (_, downloadValue, __) {
        return SizedBox.square(
          dimension: 50,
          child: Center(
            child: downloadValue == 0 ||
                    lastDownloadedSongIdListener.value != widget.song['ytid']
                ? IconButton(
                    color: accent.primary,
                    icon: const Icon(FluentIcons.arrow_download_24_regular),
                    iconSize: 24.0,
                    onPressed: () {
                      if (downloadListenerNotifier.value == 0)
                        downloadSong(context, widget.song);
                    },
                  )
                : GestureDetector(
                    child: Stack(
                      children: [
                        Center(
                          child: CircularProgressIndicator(
                            color: accent.primary,
                            value: downloadValue == 1
                                ? null
                                : downloadValue.toDouble(),
                          ),
                        ),
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Center(
                              child: Text(
                                '${downloadListenerNotifier.value}%',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
