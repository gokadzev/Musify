/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/version.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.about)),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 14),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Musify',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'paytoneOne',
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'v$appVersion',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
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
                subtitle: const Text('WEB & APP Developer'),
                trailing: Wrap(
                  children: <Widget>[
                    _SocialButton(
                      icon: FluentIcons.code_24_filled,
                      tooltip: 'Github',
                      onPressed: () {
                        launchURL(Uri.parse('https://github.com/gokadzev'));
                      },
                    ),
                    const SizedBox(width: 8),
                    _SocialButton(
                      icon: FluentIcons.globe_24_filled,
                      tooltip: 'Website',
                      onPressed: () {
                        launchURL(Uri.parse('https://gokadzev.github.io'));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
