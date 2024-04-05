import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/widgets/marque.dart';

class PlaylistHeader extends StatelessWidget {
  PlaylistHeader(
    this.image,
    this.title,
    this.headerDescription,
    this.songsLength, {
    super.key,
  });

  final Widget image;
  final String title;
  final String? headerDescription;
  final int songsLength;

  @override
  Widget build(BuildContext context) {
    final _primaryColor = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        image,
        const SizedBox(width: 10),
        SizedBox(
          width: MediaQuery.of(context).size.width / 2.3,
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              if (headerDescription != null)
                MarqueeWidget(
                  child: Text(
                    headerDescription!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                '[ $songsLength ${context.l10n!.songs} ]'.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
