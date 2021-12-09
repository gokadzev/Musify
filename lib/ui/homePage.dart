import 'package:Musify/services/audio_manager.dart';
import 'package:Musify/style/appColors.dart';
import 'package:Musify/ui/aboutPage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:Musify/API/musify.dart';
import 'package:Musify/music.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 10, bottom: 20.0)),
            Center(
              child: Row(children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(),
                    child: Center(
                      child: GradientText(
                        "Musify.",
                        shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
                        gradient: LinearGradient(colors: [
                          accent,
                          accent,
                        ]),
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            Padding(padding: EdgeInsets.only(top: 20)),
            FutureBuilder(
              future: topSongs(),
              builder: (context, data) {
                if (data.hasData)
                  return Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 30.0, bottom: 10, left: 8),
                          child: Text(
                            "Top 10 Songs",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 22,
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          //padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                          height: MediaQuery.of(context).size.height * 0.25,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              return getTopSong(
                                  (data as dynamic).data[index]["image"],
                                  (data as dynamic).data[index]["title"],
                                  (data as dynamic).data[index]["more_info"]
                                      ["primary_artists"],
                                  (data as dynamic).data[index]["id"]);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                return Center(
                    child: Padding(
                  padding: const EdgeInsets.all(35.0),
                  child: CircularProgressIndicator(
                    valueColor: new AlwaysStoppedAnimation<Color>(accent),
                  ),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget getTopSong(String image, String title, String subtitle, int id) {
    return InkWell(
      onTap: () {
        playSong(id, context);
      },
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.17,
            width: MediaQuery.of(context).size.width * 0.4,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: CachedNetworkImageProvider(image),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            title
                .split("(")[0]
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\""),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
