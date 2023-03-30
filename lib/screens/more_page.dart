import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/about_page.dart';
import 'package:musify/screens/local_music_page.dart';
import 'package:musify/screens/playlists_page.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/screens/setup_page.dart';
import 'package:musify/screens/user_liked_songs_page.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/update_manager.dart';
import 'package:musify/style/app_colors.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/url_launcher.dart';
import 'package:musify/widgets/setting_bar.dart';
import 'package:musify/widgets/setting_switch_bar.dart';

final prefferedFileExtension = ValueNotifier<String>(
  Hive.box('settings').get('audioFileType', defaultValue: 'mp3') as String,
);
final playNextSongAutomatically = ValueNotifier<bool>(
  Hive.box('settings').get('playNextSongAutomatically', defaultValue: false),
);

final useSystemColor = ValueNotifier<bool>(
  Hive.box('settings').get('useSystemColor', defaultValue: true),
);

final foregroundService = ValueNotifier<bool>(
  Hive.box('settings').get('foregroundService', defaultValue: false) as bool,
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
        title: Text(
          AppLocalizations.of(context)!.more,
        ),
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
            color: colorScheme.primary,
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
          AppLocalizations.of(context)!.localMusic,
          FluentIcons.arrow_download_24_filled,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LocalMusicPage()),
            ),
          },
        ),

        // CATEGORY: SETTINGS
        Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(
            color: colorScheme.primary,
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
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.primary,
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
                      itemCount: availableColors.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: 15,
                            bottom: 15,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (availableColors.length > index)
                                GestureDetector(
                                  onTap: () {
                                    addOrUpdateData(
                                      'settings',
                                      'accentColor',
                                      availableColors[index].value,
                                    );
                                    MyApp.updateAppState(
                                      context,
                                      newAccentColor: availableColors[index],
                                      useSystemColor: false,
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
                                              ? availableColors[index]
                                                  .withAlpha(150)
                                              : availableColors[index],
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
                        color: colorScheme.primary,
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
                                MyApp.updateAppState(
                                  context,
                                  newThemeMode: availableModes[index],
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
                        color: colorScheme.primary,
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
                              ),
                              onTap: () {
                                addOrUpdateData(
                                  'settings',
                                  'language',
                                  availableLanguages[index],
                                );
                                MyApp.updateAppState(
                                  context,
                                  newLocale: Locale(
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
        SettingSwitchBar(
          AppLocalizations.of(context)!.useSystemColor,
          FluentIcons.toggle_left_24_filled,
          useSystemColor.value,
          (value) {
            addOrUpdateData(
              'settings',
              'useSystemColor',
              value,
            );
            useSystemColor.value = value;
            MyApp.updateAppState(
              context,
              newAccentColor: colorScheme.primary,
              useSystemColor: value,
            );
            showToast(
              AppLocalizations.of(context)!.settingChangedMsg,
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: foregroundService,
          builder: (_, foregroundValue, __) {
            return SettingSwitchBar(
              AppLocalizations.of(context)!.foregroundService,
              FluentIcons.eye_24_filled,
              foregroundValue,
              (value) {
                addOrUpdateData(
                  'settings',
                  'foregroundService',
                  value,
                );

                foregroundService.value = value;

                showToast(
                  AppLocalizations.of(context)!.settingChangedAndRestartMsg,
                );
              },
            );
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
                        color: colorScheme.primary,
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
        SettingBar(
          AppLocalizations.of(context)!.setup,
          FluentIcons.settings_24_filled,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SetupPage()),
            ),
          },
        ),

        // CATEGORY: TOOLS
        Text(
          AppLocalizations.of(context)!.tools,
          style: TextStyle(
            color: colorScheme.primary,
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
            backupData(context).then(
              showToast,
            ),
          },
        ),
        SettingBar(
          AppLocalizations.of(context)!.restoreUserData,
          FluentIcons.cloud_add_24_filled,
          () => {
            restoreData(context).then(
              showToast,
            ),
          },
        ),
        isUpdaterEnabled
            ? SettingBar(
                AppLocalizations.of(context)!.downloadAppUpdate,
                FluentIcons.arrow_download_24_filled,
                () => {
                  checkAppUpdates(context),
                },
              )
            : const SizedBox(),
        // CATEGORY: OTHERS
        Text(
          AppLocalizations.of(context)!.others,
          style: TextStyle(
            color: colorScheme.primary,
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
