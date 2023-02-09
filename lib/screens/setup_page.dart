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
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.setup,
          style: TextStyle(
            color: accent.primary,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: <Widget>[
              Text(
                AppLocalizations.of(context)!.localSongsFolders,
                style: TextStyle(
                  color: accent.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: () async => {
                        await FilePicker.platform.getDirectoryPath().then(
                              (value) => {
                                if (value is String)
                                  {localSongsFolders.add(value)},
                              },
                            ),
                        addOrUpdateData(
                          'settings',
                          'localSongsFolders',
                          localSongsFolders,
                        ),
                        setState(() {})
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(accent.primary),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.add.toUpperCase(),
                        style: TextStyle(
                          color: isAccentWhite(),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () async => {
                          localSongsFolders = [],
                          addOrUpdateData(
                            'settings',
                            'localSongsFolders',
                            localSongsFolders,
                          ),
                          setState(() {})
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(accent.primary),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.clear.toUpperCase(),
                          style: TextStyle(
                            color: isAccentWhite(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (localSongsFolders.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  itemCount: localSongsFolders.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 5),
                      child: Card(
                        child: ListTile(
                          title: MarqueeWidget(
                            child: Text(localSongsFolders[index]),
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 15),
                  child: Card(
                    child: ListTile(
                      title: Text(AppLocalizations.of(context)!.noDirectories),
                    ),
                  ),
                ),
              Text(
                AppLocalizations.of(context)!.downloadSongsFolder,
                style: TextStyle(
                  color: accent.primary,
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
                          MaterialStateProperty.all<Color>(accent.primary),
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
