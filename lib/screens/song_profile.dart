import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/widgets/custom_bar.dart';

class SongProfile extends StatefulWidget {
  final String songId;
  const SongProfile({
    super.key,
    required this.songId,
  });

  @override
  _SongProfileState createState() => _SongProfileState();
}

class _SongProfileState extends State<SongProfile> {
  double _sliderValue = 1;
  dynamic _songProfile;

  @override
  void initState() {
    super.initState();
    _getSongProfiles();
  }

  Future<void> _getSongProfiles() async {
    final songProfile = await getData('songProfiles', widget.songId);
    setState(() {
      _songProfile = songProfile;
      _sliderValue = songProfile;
    });
  }

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
              width: 300,
              child: Row(
                children: [
                  Slider(
                    label: 'Select Volume',
                    value: _sliderValue,
                    onChanged: (value) {
                      setState(() {
                        _sliderValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      addOrUpdateData('songProfiles', widget.songId, value);
                      _getSongProfiles();
                    },
                    min: 0.1,
                    max: 3,
                  ),
                  Text(
                    _sliderValue.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
