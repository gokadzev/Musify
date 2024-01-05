import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/version.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/about_page.dart';
import 'package:musify/screens/playlists_page.dart';
import 'package:musify/screens/recently_played_page.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/screens/user_liked_playlists_page.dart';
import 'package:musify/screens/user_liked_songs_page.dart';
import 'package:musify/screens/user_offline_songs_page.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/services/update_manager.dart';
import 'package:musify/style/app_colors.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/url_launcher.dart';
import 'package:musify/widgets/setting_bar.dart';
import 'package:musify/widgets/setting_switch_bar.dart';

class MorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n!.more,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // CATEGORY: PAGES
            Text(
              context.l10n!.pages,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            SettingBar(
              context.l10n!.recentlyPlayed,
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
              context.l10n!.playlists,
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
              context.l10n!.userLikedSongs,
              FluentIcons.heart_24_filled,
              () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserLikedSongsPage(),
                  ),
                ),
              },
            ),
            SettingBar(
              context.l10n!.userOfflineSongs,
              FluentIcons.cellular_off_24_filled,
              () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserOfflineSongsPage(),
                  ),
                ),
              },
            ),
            SettingBar(
              context.l10n!.userLikedPlaylists,
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

            // CATEGORY: SETTINGS
            Text(
              context.l10n!.settings,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            SettingBar(
              context.l10n!.accentColor,
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
                          borderRadius: BorderRadius.circular(20),
                        ),
                        width: MediaQuery.of(context).size.width * 0.90,
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
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (availableColors.length > index)
                                    GestureDetector(
                                      onTap: () {
                                        addOrUpdateData(
                                          'settings',
                                          'accentColor',
                                          availableColors[index].value,
                                        );
                                        Musify.updateAppState(
                                          context,
                                          newAccentColor:
                                              availableColors[index],
                                          useSystemColor: false,
                                        );
                                        showToast(
                                          context,
                                          context.l10n!.accentChangeMsg,
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
                                    ),
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
              context.l10n!.themeMode,
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
                      ThemeMode.dark,
                    ];
                    return Center(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.primary,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        width: MediaQuery.of(context).size.width * 0.90,
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
                                    Musify.updateAppState(
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
              context.l10n!.language,
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
                          borderRadius: BorderRadius.circular(20),
                        ),
                        width: MediaQuery.of(context).size.width * 0.90,
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
                                    Musify.updateAppState(
                                      context,
                                      newLocale: Locale(
                                        appLanguages[
                                            availableLanguages[index]]!,
                                      ),
                                    );

                                    showToast(
                                      context,
                                      context.l10n!.languageMsg,
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
              context.l10n!.dynamicColor,
              FluentIcons.toggle_left_24_filled,
              useSystemColor.value,
              (value) {
                addOrUpdateData(
                  'settings',
                  'useSystemColor',
                  value,
                );
                useSystemColor.value = value;
                Musify.updateAppState(
                  context,
                  newAccentColor: primaryColor,
                  useSystemColor: value,
                );
                showToast(
                  context,
                  context.l10n!.settingChangedMsg,
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
                      'sponsorBlockSupport',
                      value,
                    );
                    sponsorBlockSupport.value = value;
                    showToast(
                      context,
                      context.l10n!.settingChangedMsg,
                    );
                  },
                );
              },
            ),

            SettingBar(
              context.l10n!.audioQuality,
              Icons.music_note,
              () {
                showModalBottomSheet(
                  isDismissible: true,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (BuildContext context) {
                    final availableQualities = ['low', 'medium', 'high'];

                    return Center(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.primary,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        width: MediaQuery.of(context).size.width * 0.90,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: availableQualities.length,
                          itemBuilder: (context, index) {
                            final quality = availableQualities[index];
                            final isCurrentQuality =
                                audioQualitySetting.value == quality;

                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Card(
                                elevation: isCurrentQuality ? 0 : 4,
                                child: ListTile(
                                  title: Text(quality),
                                  onTap: () {
                                    addOrUpdateData(
                                      'settings',
                                      'audioQuality',
                                      quality,
                                    );
                                    audioQualitySetting.value = quality;

                                    showToast(
                                      context,
                                      context.l10n!.audioQualityMsg,
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
                );
              },
            ),

            // CATEGORY: TOOLS
            Text(
              context.l10n!.tools,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            SettingBar(
              context.l10n!.clearCache,
              FluentIcons.broom_24_filled,
              () => {
                clearCache(),
                showToast(
                  context,
                  '${context.l10n!.cacheMsg}!',
                ),
              },
            ),
            SettingBar(
              context.l10n!.clearSearchHistory,
              FluentIcons.history_24_filled,
              () => {
                searchHistory = [],
                deleteData('user', 'searchHistory'),
                showToast(context, '${context.l10n!.searchHistoryMsg}!'),
              },
            ),
            SettingBar(
              context.l10n!.backupUserData,
              FluentIcons.cloud_sync_24_filled,
              () => {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Text(context.l10n!.folderRestrictions),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            context.l10n!.understand.toUpperCase(),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                ).then(
                  (value) => backupData(context).then(
                    (response) => showToast(context, response),
                  ),
                ),
              },
            ),
            SettingBar(
              context.l10n!.restoreUserData,
              FluentIcons.cloud_add_24_filled,
              () => {
                restoreData(context).then(
                  (response) => showToast(context, response),
                ),
              },
            ),
            if (!isFdroidBuild)
              SettingBar(
                context.l10n!.downloadAppUpdate,
                FluentIcons.arrow_download_24_filled,
                () => {
                  checkAppUpdates(context),
                },
              ),
            // CATEGORY: BECOME A SPONSOR
            Text(
              context.l10n!.becomeSponsor,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Card(
                color: colorScheme.primary,
                child: ListTile(
                  leading: const Icon(
                    FluentIcons.heart_24_filled,
                    color: Colors.white,
                  ),
                  title: Text(
                    context.l10n!.sponsorProject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () => {
                    launchURL(
                      Uri.parse('https://ko-fi.com/gokadzev'),
                    ),
                  },
                ),
              ),
            ),
            // CATEGORY: OTHERS
            Text(
              context.l10n!.others,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            SettingBar(
              context.l10n!.licenses,
              FluentIcons.document_24_filled,
              () => {
                Navigator.push(
                  context,
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
              '${context.l10n!.copyLogs} (${logger.getLogCount()})',
              FluentIcons.error_circle_24_filled,
              () async => {showToast(context, await logger.copyLogs(context))},
            ),
            SettingBar(
              context.l10n!.about,
              FluentIcons.book_information_24_filled,
              () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                ),
              },
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
