import 'package:delayed_display/delayed_display.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 25.0, horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(),
              child: Center(
                child: Text(
                  "Musify.",
                  style: TextStyle(
                      fontSize: 35, fontWeight: FontWeight.w800, color: accent),
                ),
              ),
            ),
            Expanded(
                child: FutureBuilder(
                    future: get7Music("PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx"),
                    builder: (context, data) {
                      if (data.hasData) {
                        return Container(
                          child: Wrap(
                            children: <Widget>[
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 30, bottom: 10),
                                child: Text(
                                  "Recommended for you",
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.50,
                                  child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: (data as dynamic).data.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                            padding: EdgeInsets.only(right: 25),
                                            child: cubeContainer(
                                                (data as dynamic).data[index]
                                                    ["highResImage"],
                                                (data as dynamic).data[index]
                                                    ["title"],
                                                (data as dynamic).data[index]
                                                        ["more_info"]
                                                    ["primary_artists"],
                                                (data as dynamic).data[index]));
                                      }))
                            ],
                          ),
                        );
                      } else {
                        return Center(
                            child: Padding(
                          padding: const EdgeInsets.all(35.0),
                          child: CircularProgressIndicator(
                            valueColor:
                                new AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ));
                      }
                    })),
            Expanded(
                child: FutureBuilder(
                    future: get7Music("PL7zsB-C3aNu2yRY2869T0zj1FhtRIu5am"),
                    builder: (context, data) {
                      if (data.hasData) {
                        return Container(
                          child: Wrap(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 30, bottom: 10, left: 8),
                                child: Text(
                                  "New Music",
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.50,
                                  child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: (data as dynamic).data.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                            padding: EdgeInsets.only(right: 25),
                                            child: cubeContainer(
                                                (data as dynamic).data[index]
                                                    ["highResImage"],
                                                (data as dynamic).data[index]
                                                    ["title"],
                                                (data as dynamic).data[index]
                                                        ["more_info"]
                                                    ["primary_artists"],
                                                (data as dynamic).data[index]));
                                      }))
                            ],
                          ),
                        );
                      } else {
                        return Center(
                            child: Padding(
                          padding: const EdgeInsets.all(35.0),
                          child: CircularProgressIndicator(
                            valueColor:
                                new AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ));
                      }
                    }))
          ],
        ),
      ),
    ));
  }

  Widget cubeContainer(String image, String title, String singer, song) {
    var size = MediaQuery.of(context).size;
    return DelayedDisplay(
        delay: Duration(milliseconds: 200),
        fadingDuration: Duration(milliseconds: 400),
        child: InkWell(
          onTap: () {
            playSong(song);
          },
          child: Column(
            children: [
              Container(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  color: Colors.transparent,
                  child: Container(
                    height: size.height / 4,
                    width: size.width / 1.9,
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
              const SizedBox(
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
              const SizedBox(
                height: 2,
              ),
              Text(
                singer,
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
