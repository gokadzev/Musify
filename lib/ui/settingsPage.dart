import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/helper/version.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/aboutPage.dart';
import 'package:musify/ui/userLikedSongsPage.dart';
import 'package:musify/ui/userPlaylistsPage.dart';

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
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
        centerTitle: true,
        title: Text(
          "Settings",
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
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
          child: Card(
            color: bgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 2.3,
            child: ListTile(
              leading: Icon(MdiIcons.shapeOutline, color: accent),
              title: Text(
                'Accent Color',
                style: TextStyle(color: accent),
              ),
              onTap: () {
                showModalBottomSheet(
                  isDismissible: true,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (BuildContext context) {
                    final List<int> colors = [
                      0xFFFFCDD2,
                      0xFFF8BBD0,
                      0xFFE1BEE7,
                      0xFFD1C4E9,
                      0xFFC5CAE9,
                      0xFF8C9EFF,
                      0xFFBBDEFB,
                      0xFF82B1FF,
                      0xFFB3E5FC,
                      0xFF80D8FF,
                      0xFFB2EBF2,
                      0xFF84FFFF,
                      0xFFB2DFDB,
                      0xFFA7FFEB,
                      0xFFC8E6C9,
                      0xFFACE1AF,
                      0xFFB9F6CA,
                      0xFFDCEDC8,
                      0xFFCCFF90,
                      0xFFF0F4C3,
                      0xFFF4FF81,
                      0xFFFFF9C4,
                      0xFFFFFF8D,
                      0xFFFFECB3,
                      0xFFFFE57F,
                      0xFFFFE0B2,
                      0xFFFFD180,
                      0xFFFFCCBC,
                      0xFFFF9E80,
                      0xFFFD5C63,
                      0xFFFFFFFF
                    ];
                    return Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(
                            color: accent,
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20),
                          ),
                        ),
                        width:
                            MediaQuery.of(context).copyWith().size.width * 0.90,
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
                                top: 15.0,
                                bottom: 15.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (colors.length - 1 > index)
                                    GestureDetector(
                                      onTap: () {
                                        addOrUpdateData(
                                          "settings",
                                          "accentColor",
                                          colors[index],
                                        );
                                        accent = Color(colors[index]);
                                        Fluttertoast.showToast(
                                          backgroundColor: accent,
                                          textColor: Colors.white,
                                          msg:
                                              "Accent Color has been Changed, move to other page to see changes!",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.BOTTOM,
                                          fontSize: 14.0,
                                        );
                                        Navigator.pop(context);
                                      },
                                      child: Material(
                                        elevation: 4.0,
                                        shape: const CircleBorder(),
                                        child: CircleAvatar(
                                          radius: 25,
                                          backgroundColor: Color(
                                            colors[index],
                                          ),
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
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
          child: Card(
            color: bgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 2.3,
            child: ListTile(
              leading: Icon(MdiIcons.broom, color: accent),
              title: Text(
                'Clear Cache',
                style: TextStyle(color: accent),
              ),
              onTap: () {
                clearCache();
                Fluttertoast.showToast(
                  backgroundColor: accent,
                  textColor: Colors.white,
                  msg: "Cache cleared!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  fontSize: 14.0,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
          child: Card(
            color: bgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 2.3,
            child: ListTile(
              leading: Icon(MdiIcons.account, color: accent),
              title: Text(
                'User Playlists',
                style: TextStyle(color: accent),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserPlaylistsPage(),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
          child: Card(
            color: bgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 2.3,
            child: ListTile(
              leading: Icon(MdiIcons.star, color: accent),
              title: Text(
                'User Liked Songs',
                style: TextStyle(color: accent),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserLikedSongs()),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
          child: Card(
            color: bgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 2.3,
            child: ListTile(
              leading: Icon(MdiIcons.cloudUpload, color: accent),
              title: Text(
                'Backup User Data',
                style: TextStyle(color: accent),
              ),
              onTap: () {
                backupData();
                Fluttertoast.showToast(
                  backgroundColor: accent,
                  textColor: Colors.white,
                  msg: "User Data Backuped!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  fontSize: 14.0,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
          child: Card(
            color: bgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 2.3,
            child: ListTile(
              leading: Icon(MdiIcons.cloudDownload, color: accent),
              title: Text(
                'Restore User Data',
                style: TextStyle(color: accent),
              ),
              onTap: () {
                restoreData();
                Fluttertoast.showToast(
                  backgroundColor: accent,
                  textColor: Colors.white,
                  msg: "User Data Restored! Restart app to see changes",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  fontSize: 14.0,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
          child: Card(
            color: bgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 2.3,
            child: ListTile(
              leading: Icon(MdiIcons.download, color: accent),
              title: Text(
                'Download App Update',
                style: TextStyle(color: accent),
              ),
              onTap: () {
                checkAppUpdates().then(
                  (available) => {
                    if (available == true)
                      {
                        Fluttertoast.showToast(
                          msg: "App Update Is Available And Downloading!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: accent,
                          textColor: Colors.white,
                          fontSize: 14.0,
                        ),
                        downloadAppUpdates()
                      }
                    else
                      {
                        Fluttertoast.showToast(
                          msg: "App Update Is Not Available!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: accent,
                          textColor: Colors.white,
                          fontSize: 14.0,
                        )
                      }
                  },
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
          child: Card(
            color: bgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 2.3,
            child: ListTile(
              leading: Icon(MdiIcons.information, color: accent),
              title: Text(
                'About',
                style: TextStyle(color: accent),
              ),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => AboutPage()));
              },
            ),
          ),
        ),
      ],
    );
  }
}
