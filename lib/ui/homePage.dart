import 'package:delayed_display/delayed_display.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';

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
                      child: Text(
                        "Musify.",
                        style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w800,
                            color: accent),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            Padding(padding: EdgeInsets.only(top: 20)),
            FutureBuilder(
              future: getTop50(),
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
                            "Top 50 Songs",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 18,
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.25,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 50,
                            itemBuilder: (context, index) {
                              return getTopSong(
                                  (data as dynamic).data[index]["image"],
                                  (data as dynamic).data[index]["title"],
                                  (data as dynamic).data[index]["more_info"]
                                      ["primary_artists"],
                                  (data as dynamic).data[index]);
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

  Widget getTopSong(String image, String title, String subtitle, song) {
    return DelayedDisplay(
        delay: Duration(milliseconds: 200),
        fadingDuration: Duration(milliseconds: 600),
        child: InkWell(
          onTap: () {
            playSong(song);
          },
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.19,
                width: MediaQuery.of(context).size.width * 0.45,
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
                  color: accent,
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
                  color: Colors.white60,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ));
  }
}
