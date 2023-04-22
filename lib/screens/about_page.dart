import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/version.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n()!.about,
        ),
      ),
      body: const SingleChildScrollView(child: AboutCards()),
    );
  }
}

class AboutCards extends StatelessWidget {
  const AboutCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 17, left: 8, right: 8, bottom: 6),
          child: Column(
            children: <Widget>[
              ListTile(
                title: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Center(
                    child: Text(
                      'Musify  | $appVersion',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8, left: 10, right: 10),
          child: Divider(
            color: Colors.white24,
            thickness: 0.8,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
          child: Card(
            child: ListTile(
              leading: Container(
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: NetworkImage(
                      'https://avatars.githubusercontent.com/u/79704324?v=4',
                    ),
                  ),
                ),
              ),
              title: const Text(
                'Valeri Gokadze',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Web/APP Developer',
              ),
              trailing: Wrap(
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      FluentIcons.code_24_filled,
                      color: colorScheme.primary,
                    ),
                    tooltip: 'Github',
                    onPressed: () {
                      launchURL(
                        Uri.parse('https://github.com/gokadzev'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
