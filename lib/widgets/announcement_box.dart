import 'package:flutter/material.dart';
import 'package:musify/utilities/url_launcher.dart';

class AnnouncementBox extends StatelessWidget {
  const AnnouncementBox({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.url,
  });
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => launchURL(Uri.parse(url)),
        child: Card(
          color: backgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          elevation: 0.1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: textColor,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
