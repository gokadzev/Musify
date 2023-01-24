import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:musify/customWidgets/setting_bar.dart';
import 'package:musify/helper/flutter_toast.dart';
import 'package:musify/helper/url_launcher.dart';
import 'package:musify/helper/version.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/style/appTheme.dart';
import 'package:musify/ui/aboutPage.dart';
import 'package:musify/ui/downloadedSongsPage.dart';
import 'package:musify/ui/localSongsPage.dart';
import 'package:musify/ui/playlistsPage.dart';
import 'package:musify/ui/searchPage.dart';
import 'package:musify/ui/userLikedSongsPage.dart';

final prefferedFileExtension = ValueNotifier<String>(
  Hive.box('settings').get('audioFileType', defaultValue: 'mp3') as String,
);
final playNextSongAutomatically = ValueNotifier<bool>(
  Hive.box('settings').get('playNextSongAutomatically', defaultValue: false),
);
final sponsorBlockSupport = ValueNotifier<bool>(
  Hive.box('settings').get('sponsorBlockSupport', defaultValue: false),
);

final useSystemColor = ValueNotifier<bool>(
  Hive.box('settings').get('useSystemColor', defaultValue: true),
);

class MorePage extends StatefulWidget {
  @override
  _MorePageState createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.more,
          style: TextStyle(
            color: accent.primary,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(child: SettingsCards()),
    );
  }
}

class SettingsCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // CATEGORY: PAGES
        Text(
          AppLocalizations.of(context)!.pages,
          style: TextStyle(
            color: accent.primary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        SettingBar(
          AppLocalizations.of(context)!.playlists,
          FluentIcons.list_24_filled,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistsPage(),
              ),
            ),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.userLikedSongs,
          FluentIcons.star_24_filled,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserLikedSongs()),
            ),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.localSongs,
          FluentIcons.arrow_download_24_filled,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LocalSongsPage()),
            ),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.downloadedSongs,
          FluentIcons.save_24_filled,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DownloadedSongsPage()),
            ),
          },
        ),

        // CATEGORY: SETTINGS
        Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(
            color: accent.primary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        SettingBar(
          AppLocalizations.of(context)!.accentColor,
          FluentIcons.color_24_filled,
          () => {
            showModalBottomSheet(
              isDismissible: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (BuildContext context) {
                final colors = <Color>[
                  const Color(0xFF9ACD32),
                  const Color(0xFF00FA9A),
                  const Color(0xFFF08080),
                  const Color(0xFF6495ED),
                  const Color(0xFFFFAFCC),
                  const Color(0xFFC8B6FF),
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.pink,
                  Colors.teal,
                  Colors.lime,
                  Colors.indigo,
                  Colors.cyan,
                  Colors.brown,
                  Colors.amber,
                  Colors.deepOrange,
                  Colors.deepPurple,
                ];
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accent.primary,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    width: MediaQuery.of(context).copyWith().size.width * 0.90,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                      ),
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: colors.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: 15,
                            bottom: 15,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (colors.length > index)
                                GestureDetector(
                                  onTap: () {
                                    addOrUpdateData(
                                      'settings',
                                      'accentColor',
                                      colors[index].value,
                                    );
                                    MyApp.setAccentColor(
                                      context,
                                      colors[index],
                                      false,
                                    );
                                    showToast(
                                      AppLocalizations.of(context)!
                                          .accentChangeMsg,
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: Material(
                                    elevation: 4,
                                    shape: const CircleBorder(),
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor:
                                          themeMode == ThemeMode.light
                                              ? colors[index].withAlpha(150)
                                              : colors[index],
                                    ),
                                  ),
                                )
                              else
                                const SizedBox.shrink()
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.themeMode,
          FluentIcons.weather_sunny_28_filled,
          () => {
            showModalBottomSheet(
              isDismissible: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (BuildContext context) {
                final availableModes = [
                  ThemeMode.system,
                  ThemeMode.light,
                  ThemeMode.dark
                ];
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accent.primary,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    width: MediaQuery.of(context).copyWith().size.width * 0.90,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: availableModes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                availableModes[index].name,
                                style: TextStyle(color: accent.primary),
                              ),
                              onTap: () {
                                addOrUpdateData(
                                  'settings',
                                  'themeMode',
                                  availableModes[index] == ThemeMode.system
                                      ? 'system'
                                      : availableModes[index] == ThemeMode.light
                                          ? 'light'
                                          : 'dark',
                                );
                                MyApp.setThemeMode(
                                  context,
                                  availableModes[index],
                                );

                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.language,
          FluentIcons.translate_24_filled,
          () => {
            showModalBottomSheet(
              isDismissible: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (BuildContext context) {
                final availableLanguages = appLanguages.keys.toList();
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accent.primary,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    width: MediaQuery.of(context).copyWith().size.width * 0.90,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: availableLanguages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                availableLanguages[index],
                                style: TextStyle(color: accent.primary),
                              ),
                              onTap: () {
                                addOrUpdateData(
                                  'settings',
                                  'language',
                                  availableLanguages[index],
                                );
                                MyApp.setLocale(
                                  context,
                                  Locale(
                                    appLanguages[availableLanguages[index]]!,
                                  ),
                                );

                                showToast(
                                  AppLocalizations.of(context)!.languageMsg,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.useSystemColor,
          FluentIcons.toggle_left_24_filled,
          () => {
            showModalBottomSheet(
              isDismissible: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (BuildContext context) {
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accent.primary,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    width: MediaQuery.of(context).copyWith().size.width * 0.90,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                AppLocalizations.of(context)!.trueMSG,
                                style: TextStyle(color: accent.primary),
                              ),
                              onTap: () {
                                addOrUpdateData(
                                  'settings',
                                  'useSystemColor',
                                  true,
                                );
                                useSystemColor.value = true;
                                MyApp.setAccentColor(
                                  context,
                                  accent.primary,
                                  true,
                                );
                                showToast(
                                  AppLocalizations.of(context)!
                                      .settingChangedMsg,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                AppLocalizations.of(context)!.falseMSG,
                                style: TextStyle(color: accent.primary),
                              ),
                              onTap: () {
                                addOrUpdateData(
                                  'settings',
                                  'useSystemColor',
                                  false,
                                );
                                useSystemColor.value = false;
                                MyApp.setAccentColor(
                                  context,
                                  accent.primary,
                                  false,
                                );
                                showToast(
                                  AppLocalizations.of(context)!
                                      .settingChangedMsg,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          },
        ),

        SettingBar(
          AppLocalizations.of(context)!.audioFileType,
          FluentIcons.multiselect_ltr_24_filled,
          () => {
            showModalBottomSheet(
              isDismissible: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (BuildContext context) {
                final availableFileTypes = ['mp3', 'flac', 'm4a'];
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accent.primary,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    width: MediaQuery.of(context).copyWith().size.width * 0.90,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: availableFileTypes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                availableFileTypes[index],
                                style: TextStyle(color: accent.primary),
                              ),
                              onTap: () {
                                addOrUpdateData(
                                  'settings',
                                  'audioFileType',
                                  availableFileTypes[index],
                                );
                                prefferedFileExtension.value =
                                    availableFileTypes[index];
                                showToast(
                                  AppLocalizations.of(context)!
                                      .audioFileTypeMsg,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          },
        ),

        // CATEGORY: TOOLS
        Text(
          AppLocalizations.of(context)!.tools,
          style: TextStyle(
            color: accent.primary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        SettingBar(
          AppLocalizations.of(context)!.clearCache,
          FluentIcons.broom_24_filled,
          () => {
            clearCache(),
            showToast(
              '${AppLocalizations.of(context)!.cacheMsg}!',
            )
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.clearSearchHistory,
          FluentIcons.history_24_filled,
          () => {
            searchHistory = [],
            deleteData('user', 'searchHistory'),
            showToast('${AppLocalizations.of(context)!.searchHistoryMsg}!'),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.backupUserData,
          FluentIcons.cloud_sync_24_filled,
          () => {
            backupData().then(
              (value) => showToast(value.toString()),
            ),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.restoreUserData,
          FluentIcons.cloud_add_24_filled,
          () => {
            restoreData().then(
              (value) => showToast(value.toString()),
            ),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.downloadAppUpdate,
          FluentIcons.arrow_download_24_filled,
          () => {
            checkAppUpdates().then(
              (available) => {
                if (available == true)
                  {
                    showToast(
                      '${AppLocalizations.of(context)!.appUpdateAvailableAndDownloading}!',
                    ),
                    downloadAppUpdates()
                  }
                else
                  {
                    showToast(
                      '${AppLocalizations.of(context)!.appUpdateIsNotAvailable}!',
                    )
                  }
              },
            ),
          },
        ),
        // CATEGORY: OTHERS
        Text(
          AppLocalizations.of(context)!.others,
          style: TextStyle(
            color: accent.primary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        SettingBar(
          AppLocalizations.of(context)!.supportDonate,
          FluentIcons.heart_24_filled,
          () => {
            launchURL(
              Uri.parse('https://www.buymeacoffee.com/gokadzev18'),
            ),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.about,
          FluentIcons.book_information_24_filled,
          () => {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AboutPage()),
            ),
          },
        ),
        const SizedBox(
          height: 20,
        )
      ],
    );
  }
}
