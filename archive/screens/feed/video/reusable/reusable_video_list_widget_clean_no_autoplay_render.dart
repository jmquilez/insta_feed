import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:insta_feed/utils/video/model/video_list_data.dart';
import 'package:insta_feed/screens/feed/video/reusable/reusable_video_list_controller.dart';
import 'package:insta_feed/screens/feed/video/reusable/reusable_video_list_controller_non_autoplay.dart';
import 'package:insta_feed/utils/video/reusable/bp_registry_elem.dart';
import 'package:flutter/material.dart';
import 'package:keframe/keframe.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:nil/nil.dart';

//KEY NOTE: TOO MANY EVENT LISTENERS CAUSE JANK (TEST WITHOUT REMOVING THEM)
class ReusableVideoListWidgetCleanNoAutoplayRender extends StatefulWidget {
  final VideoListData? videoListData;
  final ReusableVideoListControllerNonAutoplay? videoListController;
  final Function? canBuildVideo;
  final int? index;
  final ScrollController? controller;

  const ReusableVideoListWidgetCleanNoAutoplayRender(
      {Key? key,
      this.videoListData,
      this.videoListController,
      this.canBuildVideo,
      this.index,
      this.controller})
      : super(key: key);

  @override
  _ReusableVideoListWidgetCleanNoAutoplayRenderState createState() =>
      _ReusableVideoListWidgetCleanNoAutoplayRenderState();
}

class _ReusableVideoListWidgetCleanNoAutoplayRenderState
    extends State<ReusableVideoListWidgetCleanNoAutoplayRender> {
  VideoListData? get videoListData => widget.videoListData;
  BetterPlayerController? controller;
  //TODO: CHECK WHEN IF NO CONTROLLERS LEFT
  StreamController<BetterPlayerController?>
      betterPlayerControllerStreamController = StreamController.broadcast();
  bool _initialized = false;
  Timer? _timer;

  //TODO: CHANGE VISIBLEFRACTION AND SCROLLING SPEED TRIGGERING FOR CANBUILDVIDEO? TOO?
  @override
  void initState() {
    super.initState();
  }

  // REMOVE FROM CACHE??
  @override
  void dispose() {
    betterPlayerControllerStreamController.close();
    super.dispose();
  }

  // Computationally expensive
  int _factorial(int n) {
    return (n == 0) ? 1 : n * _factorial(n - 1) * _factorial(n - 2);
  }

  void expensive(int n) {
    String str = "";
    for (var i = 0; i < n; i++) {
      str = '$str $i';
    }
    print(str);
  }

  //FLUTTER VERSION IN BETA, ERROR THERE??
  Future<void> _setupController() async {
    print("setting controller up");
    if (controller == null) {
      controller = await widget.videoListController!
          .getBetterPlayerControllerReassign(widget.index!);
      //TODO, NOTE: ADDING HERE MAKES "Hola" SCREEN APPEAR FREQUENTLY
      /*if (!betterPlayerControllerStreamController.isClosed &&
          controller != null) {
        betterPlayerControllerStreamController.add(controller);
      }*/
      if (controller != null) {
        await controller!.setupDataSource(BetterPlayerDataSource.network(
          videoListData!.videoUrl,
          cacheConfiguration:
              //change other parameters of cacheConfiguration
              //USECACHE FOR??
              const BetterPlayerCacheConfiguration(useCache: true /*false*/),
          //TODO, CHECK: NOT BUFFERING ENOUGH MS DISABLES VIDEO FROM BEING PLAYED??
          bufferingConfiguration: const BetterPlayerBufferingConfiguration(
              minBufferMs: 2500, //5000 //25000,
              maxBufferMs:
                  3000, //6000 //12500 //50000, //100000 //1000000 //6553600,
              bufferForPlaybackMs: 1000, //1250, //TODO: CHANGE
              bufferForPlaybackAfterRebufferMs: 2000 //2500 //TODO: CHANGE
              ),
        ));
        //TODO: TRY ABUSING SHARED CONNECTION
        if (!betterPlayerControllerStreamController.isClosed) {
          betterPlayerControllerStreamController.add(controller);
        }
        //TODO, NOTE: REPLACE "?" WITH "!"? --> null check operator used on a null value
        controller!.addEventsListener(onPlayerEvent);
      }
    }
  }

  //TODO, CHECK: IS GETTING CALLED EVERY TIME?
  Future<void> _freeController() async {
    //??
    //TODO: CHECK FOR JITTER, WHETHTER IT IS DEFINITIVE OR NOT
    if (!_initialized) {
      _initialized = true;
      //return;
    }
    if (controller != null) {
      await controller!.pause();
      controller!.removeEventsListener(onPlayerEvent);
      BpRegistryElem? elem = widget.videoListController!.getElem(controller!);
      widget.videoListController!.freeBetterPlayerController(elem);
      controller = null;
      if (!betterPlayerControllerStreamController.isClosed) {
        betterPlayerControllerStreamController.add(null);
      }
    }
  }

  Future<void> onPlayerEvent(BetterPlayerEvent event) async {
    if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
      videoListData!.lastPosition = event.parameters!["progress"] as Duration?;
    }
    //TODO, CHECK: RECONNECT TO SURFACE LAG??
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      //CHECK FOR "NULL OPERATOR USED ON A NULL VALUE" ERROR --> pause video on disappear??
      //await controller!.play();
      print("INITIALIZED_EVENT, INDEX: ${widget.index}");
      if (!controller!.isPlaying()!) {
        await controller!.play();
      }
      //await controller!.play();
      print("PLAYING: ${controller!.isPlaying()}, index: ${widget.index}");
      if (videoListData!.lastPosition != null) {
        //TODO: set await --> KEY
        await controller!.seekTo(videoListData!.lastPosition!);
      }
      //TODO: CHECK ON DEACTIVATE
      /* if (videoListData!.wasPlaying!) {
        await controller!.play();
      }*/
    }
  }

  ///TODO: Handle "setState() or markNeedsBuild() called during build." error
  ///when fast scrolling through the list
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              videoListData!.videoTitle,
              style: const TextStyle(fontSize: 50),
            ),
          ),
          VisibilityDetector(
            key: Key(hashCode.toString() + DateTime.now().toString()),
            onVisibilityChanged: (info) async {
              if (!widget.canBuildVideo!()) {
                //AWAIT??
                //TODO: CHECK KEYS??
                _timer?.cancel();
                //NOTE: NO CHILD WIDGETS TEND TO JANK MORE
                //TODO, NOTE: NEEDED?
                _timer = null;
                //WIFI CONNECTION IMPACT??
                //Simulatneous creation of several timers blocks ui when loading multiple videos at a time?
                //TODO: play with delays
                _timer = Timer(
                    const Duration(milliseconds: 250 /*100*/ /*250*/ /*500*/),
                    () async {
                  //TODO, NOTE: Synchronized, as in java?
                  if (info.visibleFraction >= 0.9 /*0.9*/ /*0.8*/ /*0.6*/) {
                    if (controller == null) {
                      await _setupController();
                    }
                  } else /*if (info.visibleFraction <= 0.3)*/ {
                    await _freeController();
                  }
                });
                return;
              }
              //check if "_setupController" calls do not match
              if (info.visibleFraction >= 0.9 /*0.9*/ /*0.8*/ /*0.6*/) {
                if (controller == null) {
                  await _setupController();
                }
              } else /*if (info.visibleFraction <= 0.3)*/ {
                await _freeController();
              }
            },
            //CONDITIONAL JANKING??
            // TODO: REMOVE ALL WIDGETS, LEAVE VIDEO ONLY AND SEE WHAT HAPPENS
            // TODO SEARCH, NOTE: THE MORE WIDGETS INSIDE STREAMBUILDER, THE LAGGIER?
            child: StreamBuilder<BetterPlayerController?>(
              stream: betterPlayerControllerStreamController.stream,
              builder: (context, snapshot) {
                print(
                    "CURR_INDEX: ${widget.index}, controller: $controller"); // wait for controller to be added to stream and then re-render
                return /*Column(
                  children: [*/
                    //ADDING OVERHEAD??
                    AspectRatio(
                  aspectRatio: 16 / 9,
                  child: controller != null
                      ? BetterPlayer(
                          controller: controller!,
                        )
                      : Container(
                          color: Colors.black,
                          child: const Center(child: Text("Saludos"))
                          //TODO: REMOVE CENTER?
                          //TODO: CALCULATE HOW MUCH OVERHEAD EACH WIDGET ADDS --> MIGHT BE INTERESTING

                          ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(widget.videoListData!.videoUrl),
          ),
          Center(
            child: Wrap(children: [
              ElevatedButton(
                child: const Text("Play"),
                onPressed: () {
                  controller!.play();
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                child: const Text("Pause"),
                onPressed: () {
                  controller!.pause();
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                child: const Text("Set max volume"),
                onPressed: () {
                  controller!.setVolume(1.0);
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }

  //TODO, NOTE: RELATED TO GLOBALKEYS, CHECK
  @override
  void deactivate() {
    if (controller != null) {
      videoListData!.wasPlaying = controller!.isPlaying();
    }
    _initialized = true;
    super.deactivate();
  }
}
