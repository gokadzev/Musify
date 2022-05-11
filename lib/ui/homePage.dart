import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/services.dart';
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
        appBar: AppBar(
          systemOverlayStyle:
              SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
          centerTitle: true,
          title: Text(
            "Musify.",
            style: TextStyle(
              color: accent,
              fontSize: 35,
              fontWeight: FontWeight.w800,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 25.0, horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                    child: FutureBuilder(
                        future: get7Music("PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx"),
                        builder: (context, data) {
                          return data.hasData
                              ? Container(
                                  child: Wrap(
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 30, bottom: 10),
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
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.50,
                                          child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  (data as dynamic).data.length,
                                              itemBuilder: (context, index) {
                                                return Padding(
                                                    padding: const EdgeInsets.only(
                                                        right: 25),
                                                    child: CubeContainer(
                                                        image: (data as dynamic)
                                                                .data[index]
                                                            ["highResImage"],
                                                        fallbackImage:
                                                            (data as dynamic).data[index]
                                                                ["image"],
                                                        title: (data as dynamic)
                                                                .data[index]
                                                            ["title"],
                                                        singer: (data as dynamic)
                                                                    .data[index]
                                                                ["more_info"]
                                                            ["primary_artists"],
                                                        song: (data as dynamic)
                                                            .data[index]));
                                              }))
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Padding(
                                  padding: const EdgeInsets.all(35.0),
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        new AlwaysStoppedAnimation<Color>(
                                            accent),
                                  ),
                                ));
                        })),
                Expanded(
                    child: FutureBuilder(
                        future: get7Music("PL7zsB-C3aNu2yRY2869T0zj1FhtRIu5am"),
                        builder: (context, data) {
                          return data.hasData
                              ? Container(
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
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.50,
                                          child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  (data as dynamic).data.length,
                                              itemBuilder: (context, index) {
                                                return Padding(
                                                    padding: const EdgeInsets.only(
                                                        right: 25),
                                                    child: CubeContainer(
                                                        image: (data as dynamic)
                                                                .data[index]
                                                            ["highResImage"],
                                                        fallbackImage:
                                                            (data as dynamic).data[index]
                                                                ["image"],
                                                        title: (data as dynamic)
                                                                .data[index]
                                                            ["title"],
                                                        singer: (data as dynamic)
                                                                    .data[index]
                                                                ["more_info"]
                                                            ["primary_artists"],
                                                        song: (data as dynamic)
                                                            .data[index]));
                                              }))
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Padding(
                                  padding: const EdgeInsets.all(35.0),
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        new AlwaysStoppedAnimation<Color>(
                                            accent),
                                  ),
                                ));
                        }))
              ],
            ),
          ),
        ));
  }
}

class CubeContainer extends StatelessWidget {
  final String image;
  final String fallbackImage;
  final String title;
  final String singer;
  final dynamic song;

  const CubeContainer({
    required this.image,
    required this.fallbackImage,
    required this.title,
    required this.singer,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
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
                    height: size.height / 4.15,
                    width: size.width / 1.9,
                    child: CachedNetworkImage(
                      imageUrl: image,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          shape: BoxShape.rectangle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => CachedNetworkImage(
                        imageUrl: fallbackImage,
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            shape: BoxShape.rectangle,
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
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
