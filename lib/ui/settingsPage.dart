import 'package:Musify/style/appColors.dart';
import 'package:Musify/ui/aboutPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        systemOverlayStyle:
            SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
        centerTitle: true,
        title: GradientText(
          "Settings",
          shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
          gradient: LinearGradient(colors: [
            accent,
            accent,
          ]),
          style: TextStyle(
            color: accent,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(child: SettingsCards()),
    );
  }
}

class SettingsCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
            child: Card(
              color: Color(0xff263238),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              elevation: 2.3,
              child: ListTile(
                leading: Icon(MdiIcons.informationOutline, color: accent),
                title: Text(
                  'About',
                  style: TextStyle(color: accentLight),
                ),
                onTap: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => AboutPage()));
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
