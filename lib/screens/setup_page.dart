import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/style/app_colors.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/marque.dart';

class SetupPage extends StatefulWidget {
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.setup,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: <Widget>[
              Text(
                AppLocalizations.of(context)!.downloadSongsFolder,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async => {
                      downloadDirectory =
                          await FilePicker.platform.getDirectoryPath(),
                      addOrUpdateData(
                        'settings',
                        'downloadPath',
                        downloadDirectory,
                      ),
                      setState(() {})
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(colorScheme.primary),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.add.toUpperCase(),
                      style: TextStyle(
                        color: isAccentWhite(),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 15),
                child: Card(
                  child: ListTile(
                    title: MarqueeWidget(
                      child: Text(
                        downloadDirectory ??
                            AppLocalizations.of(context)!.noDirectory,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
