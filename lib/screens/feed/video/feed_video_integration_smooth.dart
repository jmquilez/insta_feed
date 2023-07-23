import 'dart:async';
import 'dart:math';
import 'dart:ui';

//TODO: CHECK KEFRAME
import 'package:better_player/better_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:insta_feed/utils/colors.dart';
import 'package:insta_feed/utils/video/model/video_list_data.dart';
import 'package:insta_feed/screens/feed/video/reusable/reusable_video_list_controller.dart';
import 'package:insta_feed/screens/feed/video/reusable/reusable_video_list_widget_clean.dart';
import 'package:intl/intl.dart';
import 'package:keframe/keframe.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:smooth/smooth.dart';

//TODO: stop video rendering when scrolling is too fast

//TODO: does this load the entire video?

//TODO: cache video?

//TODO: animate jank?

//NOTE: hls lags, live hls lags too, no matter size of video

class FeedVideoIntegrationSmooth extends StatefulWidget {
  const FeedVideoIntegrationSmooth({Key? key}) : super(key: key);

  @override
  State<FeedVideoIntegrationSmooth> createState() =>
      _FeedVideoIntegrationSmoothState();
}

class _FeedVideoIntegrationSmoothState
    extends State<FeedVideoIntegrationSmooth> {
  //TODO: create list with docs for cache extent
  //Connectivity jank issues??
  StreamSubscription<ConnectivityResult>? subscription;
  final Connectivity _connectivity = Connectivity();
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final ScrollController _scrollController = ScrollController();
  double? mediaQHeight;
  double? currentCacheExtent;
  int documentLength = 0;
  final _random = Random();
  final List<String> _videos = [
    "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
    "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    ////'https://techslides.com/demos/sample-videos/small.mp4'
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4"
  ];
  List<VideoListData> dataList = [];
  ReusableVideoListController? videoListController;
  bool _canBuildVideo = true;
  int lastMilli = DateTime.now().millisecondsSinceEpoch;
  List<bool> isVideo = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initConnectivity();
    _setupData();
    //TODO: CHECK PERFORMANCE
    videoListController = ReusableVideoListController();
    subscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _scrollController.addListener(() {
      print("CONTROLLER_PIXELS: ${_scrollController.position.pixels}");
      print("CURRENT_CACHE_EXTENT: $currentCacheExtent");
      print("DOCUMENT_LENGTH: $documentLength");
    });
  }

  void _setupData() {
    // index < itemCount
    for (int index = 0; index < 1000; index++) {
      var randomVideoUrl = _videos[_random.nextInt(_videos.length)];
      dataList.add(VideoListData("Video $index", randomVideoUrl));
      isVideo.add(true /*false*/ /*_random.nextBool()*/);
    }
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      Logger().e('Couldn\'t check connectivity status', e);
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    print('ESTADO_DE_CONEXIÖN:');
    print(result.toString());
    /*setState(() {
      _connectionStatus = result;
    });*/
  }

  @override
  void dispose() {
    // TODO: implement dispose
    subscription!.cancel();
    _scrollController.dispose();
    videoListController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //NOTE: MEDIAQUERY JANKS
    final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final physicalScreenSize = WidgetsBinding.instance.window.physicalSize;
    final mediaQueryHeight = physicalScreenSize.height;
    mediaQHeight = mediaQueryHeight;
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {}, icon: const Icon(Icons.airplay_rounded))
          ],
          backgroundColor: mobileBackgroundColor,
          centerTitle: true,
          /*title: SvgPicture.asset(
          'assets/ic_insta_feed.svg',
          color: primaryColor,
          height: 32,
        ),*/
        ),
        body: //const Text("Hi")
            //TODO: REPLACE WITH OTHER LISTENER??
            NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final now = DateTime.now();
            final timeDiff = now.millisecondsSinceEpoch - lastMilli;
            if (notification is ScrollUpdateNotification) {
              final pixelsPerMilli = notification.scrollDelta! / timeDiff;
              if (pixelsPerMilli.abs() > /*0.5*/ /*0.25*/ /*4*/ /*5*/ 1) {
                //TODO: CHANGE BOUNDARY
                _canBuildVideo = false;
              } else {
                _canBuildVideo = true;
              }
              lastMilli = DateTime.now().millisecondsSinceEpoch;
            }

            if (notification is ScrollEndNotification) {
              _canBuildVideo = true;
              lastMilli = DateTime.now().millisecondsSinceEpoch;
            }

            return true;
          },
          child: SizeCacheWidget(
              //estimateCount: 161,
              //TODO: SCROLLCONTROLLEREVENT??
              child: /*const Text(
                  "Hello")*/
                  //TODO, NOTE, KEY: CRASHES IF CHILD ELEMENTS ARE TOO SMALL
                  SmoothListView.builder(
                      //FOR MEMORY OPTIMIZATION --> set to false
                      ////addAutomaticKeepAlives: true, //false
                      ////shrinkWrap: false, //true
                      ////addRepaintBoundaries: true, //true
                      ////addSemanticIndexes: true, //false
                      //TODO: CHECK
                      ////primary: true, //false
                      //primary: false, //TODO: ????????
                      //TODO: calculate optimal cacheExtent, limit loadable pictures
                      //double.maxFinite??
                      ////scrollDirection: Axis.vertical,
                      ////itemExtent: 550,
                      ////cacheExtent: 500, //500
                      /*physics: //CustomPhysics(),
                        const BouncingScrollPhysics(), //const ClampingScrollPhysics(),*/
                      //TODO, NOTE: does it improve performance?
                      placeholder: PreferredSize(
                        preferredSize: const Size(double.infinity, 700),
                        child: Container(height: 700),
                      ), //TODO: CHANGE FROM 800 TO 550 OR 600 (CHECK NON-SMOOTH LISTVIEW ITEMEXTENT)
                      itemCount: 1000, //try longer
                      itemBuilder: (context, index) {
                        // interleaved videos
                        VideoListData videoListData = dataList[index];
                        videoListData.index = index;
                        //int video = Random().nextInt(10);
                        //print("VIDEO_KEY: $video");
                        print("CURRENT_LIST_INDEX: $index");
                        //TODO: CHECK USE
                        /*StreamController<BetterPlayerController?>
                            betterPlayerControllerStreamController =
                            StreamController.broadcast();*/
                        return FrameSeparateWidget(
                            index: index,
                            placeHolder: Container(
                              color: index % 2 == 0 ? Colors.red : Colors.blue,
                              height: 700,
                            ),
                            child: Container(
                              width: double.infinity,
                              //TODO, NOTE: THIS HEIGHT IS BLOCKING APP --> CHECK LIMITS / THRESHOLD
                              height: 700,
                              color: Colors.limeAccent,
                              child: ReusableVideoListWidgetClean(
                                  videoListData: videoListData,
                                  videoListController: videoListController,
                                  canBuildVideo: _checkCanBuildVideo,
                                  index: index),
                            )
                            /*const Text(
                                  "Keloke"),*/ //Wow with keframe placeholder load
                            );
                      })),
        )); //TODO, CHECK: REMOVE SCAFFOLD, TOO MUCH OVERHEAD??
  }

  bool _checkCanBuildVideo() {
    return _canBuildVideo;
  }
}
