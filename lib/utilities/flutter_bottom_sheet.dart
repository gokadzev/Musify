import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

void showCustomBottomSheet(BuildContext context, Widget content) {
  final size = MediaQuery.of(context).size;
  showBottomSheet(
    enableDrag: true,
    context: context,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      width: size.width - 15,
      height: size.height / 2.14,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              top: size.height * 0.010,
            ),
            child: IconButton(
              icon: Icon(
                FluentIcons.subtract_24_filled,
                color: Theme.of(context).colorScheme.primary,
                size: 40,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: content,
            ),
          ),
        ],
      ),
    ),
  );
}
