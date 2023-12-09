import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/extensions/audio_quality.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/audio_service.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/logger_service.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/mini_player.dart';

late MusifyAudioHandler audioHandler;

final logger = Logger();

Locale locale = const Locale('en', '');
var isFdroidBuild = false;

final _navigatorKey = GlobalKey<NavigatorState>();
final _selectedIndex = ValueNotifier<int>(0);

final appLanguages = <String, String>{
  'English': 'en',
  'Arabic': 'ar',
  'French': 'fr',
  'Georgian': 'ka',
  'German': 'de',
  'Greek': 'el',
  'Hindi': 'hi',
  'Polish': 'pl',
  'Portuguese': 'pt',
  'Spanish': 'es',
  'Turkish': 'tr',
  'Ukrainian': 'uk',
  'Vietnamese': 'vi',
};

final appSupportedLocales = appLanguages.values
    .map((languageCode) => Locale.fromSubtags(languageCode: languageCode))
    .toList();

class Musify extends StatefulWidget {
  const Musify({super.key});

  static Future<void> updateAppState(
    BuildContext context, {
    ThemeMode? newThemeMode,
    Locale? newLocale,
    Color? newAccentColor,
    bool? useSystemColor,
  }) async {
    final state = context.findAncestorStateOfType<_MusifyState>()!;
    if (newThemeMode != null) {
      state.changeTheme(newThemeMode);
    }
    if (newLocale != null) {
      state.changeLanguage(newLocale);
    }
    if (newAccentColor != null && useSystemColor != null) {
      state.changeAccentColor(newAccentColor, useSystemColor);
    }
  }

  @override
  _MusifyState createState() => _MusifyState();
}

class _MusifyState extends State<Musify> {
  void changeTheme(ThemeMode newThemeMode) {
    setState(() {
      themeMode = newThemeMode;
      brightness = getBrightnessFromThemeMode(newThemeMode);
      colorScheme = ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ).harmonized();
    });
  }

  void changeLanguage(Locale newLocale) {
    setState(() {
      locale = newLocale;
    });
  }

  void changeAccentColor(Color newAccentColor, bool systemColorStatus) {
    setState(() {
      if (useSystemColor.value != systemColorStatus) {
        useSystemColor.value = systemColorStatus;

        addOrUpdateData(
          'settings',
          'useSystemColor',
          systemColorStatus,
        );
      }

      primaryColor = newAccentColor;

      colorScheme = ColorScheme.fromSeed(
        seedColor: newAccentColor,
        brightness: brightness,
      ).harmonized();
    });
  }

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box('settings');
    final language =
        settingsBox.get('language', defaultValue: 'English') as String;
    locale = Locale(appLanguages[language] ?? 'en');
    final themeModeSetting = settingsBox.get('themeMode') as String?;

    if (themeModeSetting != null && themeModeSetting != themeMode.name) {
      themeMode = getThemeMode(themeModeSetting);
      brightness = getBrightnessFromThemeMode(themeMode);
    }

    GoogleFonts.config.allowRuntimeFetching = false;

    try {
      LicenseRegistry.addLicense(() async* {
        final license =
            await rootBundle.loadString('assets/fonts/roboto/LICENSE.txt');
        yield LicenseEntryWithLineBreaks(['google_fonts'], license);
        final license1 =
            await rootBundle.loadString('assets/fonts/paytone/OFL.txt');
        yield LicenseEntryWithLineBreaks(['google_fonts'], license1);
      });
    } catch (e) {
      logger.log('License Registration Error: $e');
    }
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        if (lightColorScheme != null &&
            darkColorScheme != null &&
            useSystemColor.value) {
          colorScheme = brightness == Brightness.light
              ? lightColorScheme
              : darkColorScheme;
        }
        final lightTheme = getAppLightTheme();

        final darkTheme = getAppDarkTheme();

        return MaterialApp(
          themeMode: themeMode,
          darkTheme: darkTheme,
          theme: lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: appSupportedLocales,
          locale: locale,
          home: NavigatorPopHandler(
            onPop: () => _navigatorKey.currentState!.pop(),
            child: Scaffold(
              body: Navigator(
                key: _navigatorKey,
                initialRoute: '/',
                onGenerateRoute: generateRoute,
              ),
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  StreamBuilder<MediaItem?>(
                    stream: audioHandler.mediaItem,
                    builder: (context, snapshot) {
                      final metadata = snapshot.data;
                      if (metadata == null) {
                        return const SizedBox.shrink();
                      } else {
                        return MiniPlayer(metadata: metadata);
                      }
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: _selectedIndex,
                    builder: (_, value, __) {
                      void onDestinationSelected(int index) {
                        if (_selectedIndex.value == index) {
                          if (_navigatorKey.currentState?.canPop() == true) {
                            _navigatorKey.currentState?.pop();
                          }
                        } else {
                          _selectedIndex.value = index;

                          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                            destinations[index],
                            ModalRoute.withName(destinations[index]),
                          );
                        }
                      }

                      return NavigationBar(
                        selectedIndex: value,
                        labelBehavior: locale == const Locale('en', '')
                            ? NavigationDestinationLabelBehavior
                                .onlyShowSelected
                            : NavigationDestinationLabelBehavior.alwaysHide,
                        onDestinationSelected: onDestinationSelected,
                        destinations: [
                          NavigationDestination(
                            icon: const Icon(FluentIcons.home_24_regular),
                            selectedIcon:
                                const Icon(FluentIcons.home_24_filled),
                            label: context.l10n?.home ?? 'Home',
                          ),
                          NavigationDestination(
                            icon: const Icon(FluentIcons.search_24_regular),
                            selectedIcon:
                                const Icon(FluentIcons.search_24_filled),
                            label: context.l10n?.search ?? 'Search',
                          ),
                          NavigationDestination(
                            icon: const Icon(FluentIcons.book_24_regular),
                            selectedIcon:
                                const Icon(FluentIcons.book_24_filled),
                            label:
                                context.l10n?.userPlaylists ?? 'User Playlists',
                          ),
                          NavigationDestination(
                            icon: const Icon(
                              FluentIcons.more_horizontal_24_regular,
                            ),
                            selectedIcon: const Icon(
                              FluentIcons.more_horizontal_24_filled,
                            ),
                            label: context.l10n?.more ?? 'More',
                          ),
                        ],
                      );
                    },
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialisation();
  runApp(const Musify());
}

Future<void> initialisation() async {
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(AudioQualityAdapter());
    await Hive.openBox('settings');
    await Hive.openBox('user');
    await Hive.openBox('cache');

    audioHandler = await AudioService.init(
      builder: MusifyAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.gokadzev.musify',
        androidNotificationChannelName: 'Musify',
        androidNotificationIcon: 'drawable/ic_launcher_foreground',
        androidShowNotificationBadge: true,
      ),
    );

    FileDownloader().configureNotification(
      running: const TaskNotification('Downloading', 'file: {filename}'),
      complete: const TaskNotification('Download finished', 'file: {filename}'),
      progressBar: true,
      tapOpensFile: true,
    );
  } catch (e) {
    logger.log('Initialization Error: $e');
  }
}
