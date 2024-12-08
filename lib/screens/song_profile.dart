import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/widgets/custom_bar.dart';

class SongProfile extends StatefulWidget {
  const SongProfile({super.key});

  @override
  _SongProfileState createState() => _SongProfileState();
}

class _SongProfileState extends State<SongProfile> {
  double _sliderValue = 1.0;

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify the Song Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomBar(
            context.l10n!.volumeSongProfile,
            FluentIcons.speaker_1_24_regular,
            trailing: SizedBox(
              width: 200,
              child: Slider(
                label: 'Select Volume',
                value: _sliderValue,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
                min: 0.1,
                max: 3,
              ),
            ),
            onTap: () {
            },
          ),
        ],
      ),
    );
  }
}
