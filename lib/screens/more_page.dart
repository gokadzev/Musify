import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/version.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/about_page.dart';
import 'package:musify/screens/local_music_page.dart';
import 'package:musify/screens/playlists_page.dart';
import 'package:musify/screens/recently_played_page.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/screens/user_liked_playlists_page.dart';
import 'package:musify/screens/user_liked_songs_page.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/services/update_manager.dart';
import 'package:musify/style/app_colors.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/url_launcher.dart';
import 'package:musify/widgets/setting_bar.dart';
import 'package:musify/widgets/setting_switch_bar.dart';

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
          context.l10n()!.more,
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
          context.l10n()!.pages,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        SettingBar(
          context.l10n()!.recentlyPlayed,
          FluentIcons.history_24_filled,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecentlyPlayed(),
              ),
            ),
          },
        ),
        SettingBar(
          context.l10n()!.playlists,
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
          context.l10n()!.userLikedSongs,
          FluentIcons.heart_24_filled,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserLikedSongs()),
            ),
          },
        ),
        SettingBar(
          context.l10n()!.userLikedPlaylists,
          FluentIcons.star_24_filled,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserLikedPlaylistsPage(),
              ),
            ),
          },
        ),

        SettingBar(
          context.l10n()!.localMusic,
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
          context.l10n()!.settings,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        SettingBar(
          context.l10n()!.accentColor,
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
                                      context,
                                      context.l10n()!.accentChangeMsg,
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
          context.l10n()!.themeMode,
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
                                  availableModes[index].name,
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
          context.l10n()!.language,
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
                                  context,
                                  context.l10n()!.languageMsg,
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
          context.l10n()!.useSystemColor,
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
              context,
              context.l10n()!.settingChangedMsg,
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: sponsorBlockSupport,
          builder: (_, value, __) {
            return SettingSwitchBar(
              'SponsorBlock',
              FluentIcons.presence_blocked_24_regular,
              value,
              (value) {
                addOrUpdateData(
                  'settings',
                  'SponsorBlockSupport',
                  value,
                );
                sponsorBlockSupport.value = value;
                showToast(
                  context,
                  context.l10n()!.settingChangedMsg,
                );
              },
            );
          },
        ),

        ValueListenableBuilder<bool>(
          valueListenable: foregroundService,
          builder: (_, foregroundValue, __) {
            return SettingSwitchBar(
              context.l10n()!.foregroundService,
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
                  context,
                  context.l10n()!.settingChangedAndRestartMsg,
                );
              },
            );
          },
        ),
        SettingBar(
          context.l10n()!.audioFileType,
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
                                  context,
                                  context.l10n()!.audioFileTypeMsg,
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
          context.l10n()!.downloadMode,
          FluentIcons.clock_arrow_download_24_filled,
          () {
            showModalBottomSheet(
              isDismissible: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (BuildContext context) {
                final availableModes = ['normal', 'faster'];
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
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(25),
                          child: Text(
                            context.l10n()!.fasterDownloadMsg,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
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
                                      availableModes[index],
                                    ),
                                    onTap: () {
                                      addOrUpdateData(
                                        'settings',
                                        'downloadMode',
                                        availableModes[index],
                                      );
                                      prefferedDownloadMode.value =
                                          availableModes[index];
                                      showToast(
                                        context,
                                        context.l10n()!.downloadModeMsg,
                                      );
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),

        // CATEGORY: TOOLS
        Text(
          context.l10n()!.tools,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        SettingBar(
          context.l10n()!.clearCache,
          FluentIcons.broom_24_filled,
          () => {
            clearCache(),
            showToast(
              context,
              '${context.l10n()!.cacheMsg}!',
            )
          },
        ),
        SettingBar(
          context.l10n()!.clearSearchHistory,
          FluentIcons.history_24_filled,
          () => {
            searchHistory = [],
            deleteData('user', 'searchHistory'),
            showToast(context, '${context.l10n()!.searchHistoryMsg}!'),
          },
        ),
        SettingBar(
          context.l10n()!.backupUserData,
          FluentIcons.cloud_sync_24_filled,
          () => {
            backupData(context).then(
              (response) => showToast(context, response),
            ),
          },
        ),
        SettingBar(
          context.l10n()!.restoreUserData,
          FluentIcons.cloud_add_24_filled,
          () => {
            restoreData(context).then(
              (response) => showToast(context, response),
            ),
          },
        ),
        if (!isFdroidBuild)
          SettingBar(
            context.l10n()!.downloadAppUpdate,
            FluentIcons.arrow_download_24_filled,
            () => {
              checkAppUpdates(context, downloadUpdateAutomatically: true),
            },
          )
        else
          const SizedBox(),
        // CATEGORY: OTHERS
        Text(
          context.l10n()!.others,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        SettingBar(
          context.l10n()!.supportDonate,
          FluentIcons.heart_24_filled,
          () => {
            launchURL(
              Uri.parse('https://ko-fi.com/gokadzev'),
            ),
          },
        ),
        SettingBar(
          'Licenses',
          FluentIcons.document_24_filled,
          () => {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LicensePage(
                  applicationName: 'Musify',
                  applicationVersion: appVersion,
                ),
              ),
            ),
          },
        ),
        SettingBar(
          context.l10n()!.about,
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
