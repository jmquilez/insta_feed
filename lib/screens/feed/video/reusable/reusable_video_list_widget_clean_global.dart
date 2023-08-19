import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:insta_feed/screens/feed/video/reusable/reusable_video_list_controller_global.dart';
import 'package:insta_feed/utils/video/model/video_list_data.dart';
import 'package:insta_feed/utils/video/reusable/bp_registry_elem.dart';
import 'package:flutter/material.dart';
//import 'package:keframe/keframe.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:nil/nil.dart';

//KEY NOTE: TOO MANY EVENT LISTENERS CAUSE JANK (TEST WITHOUT REMOVING THEM)
class ReusableVideoListWidgetCleanGlobal extends StatefulWidget {
  final VideoListData? videoListData;
  ReusableVideoListControllerGlobal? videoListController;
  final Function? canBuildVideo;
  final int? index;
  final ScrollController? controller;
  bool? render;
  ReusableVideoListWidgetCleanGlobal(
      {Key? key,
      this.videoListData,
      this.videoListController,
      this.canBuildVideo,
      this.index,
      this.controller,
      required this.render})
      : super(key: key);

  @override
  _ReusableVideoListWidgetCleanGlobalState createState() =>
      _ReusableVideoListWidgetCleanGlobalState();
}

class _ReusableVideoListWidgetCleanGlobalState
    extends State<ReusableVideoListWidgetCleanGlobal> {
  VideoListData? get videoListData => widget.videoListData;
  BetterPlayerController? controller;
  //TODO: CHECK WHEN IF NO CONTROLLERS LEFT
  StreamController<BetterPlayerController?>
      betterPlayerControllerStreamController = StreamController.broadcast();
  bool _initialized = false;
  bool _isInitializing = false;
  bool _isWaiting = false;
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
    print("setting controller up, index: ${widget.index}");
    if (controller == null) {
      controller = await widget.videoListController!
          .getBetterPlayerControllerReassign(widget.index!);
      //TODO, NOTE: ADDING HERE MAKES "Hola" SCREEN APPEAR FREQUENTLY
      /*if (!betterPlayerControllerStreamController.isClosed &&
          controller != null) {
        betterPlayerControllerStreamController.add(controller);
      }*/
      //TODO: check video autostop
      if (controller != null) {
        _isInitializing = true;
        //TODO: non-await??
        print("setting-datasource-up");
        await controller!.setupDataSource(BetterPlayerDataSource.network(
          videoListData!.videoUrl,
          cacheConfiguration:
              //change other parameters of cacheConfiguration
              //USECACHE FOR??
              //NOTE: changed
              const BetterPlayerCacheConfiguration(useCache: true /*false*/),
          //TODO, CHECK: NOT BUFFERING ENOUGH MS DISABLES VIDEO FROM BEING PLAYED??
          bufferingConfiguration: const BetterPlayerBufferingConfiguration(
              minBufferMs: 500, //2500, //5000 //25000,
              maxBufferMs:
                  100000, //3000, //6000 //12500 //50000, //100000 //1000000 //6553600,
              bufferForPlaybackMs: 400, //1250, //TODO: CHANGE
              bufferForPlaybackAfterRebufferMs: 400 //2000 //2500 //TODO: CHANGE
              ),
        ));
        //TODO: avoid playing in the background
        if (!_isInitializing) {
          _freeAfterInitializing();
        } else {
          _isInitializing = false;
          //TODO: TRY ABUSING SHARED CONNECTION
          if (!betterPlayerControllerStreamController.isClosed) {
            betterPlayerControllerStreamController.add(controller);
          }
          //TODO, NOTE: REPLACE "?" WITH "!"? --> null check operator used on a null value, revise bug
          controller!.addEventsListener(onPlayerEvent);
        }
      }
    }
  }

  //TODO, CHECK: IS GETTING CALLED EVERY TIME?
  Future<void> _freeController() async {
    print("FREEING-CONTROLLER, index: ${widget.index}");
    //??
    //TODO: CHECK FOR JITTER, WHETHTER IT IS DEFINITIVE OR NOT
    if (!_initialized) {
      _initialized = true;
      //TODO, NOTE: Causing eventListeners to not be removed??
      //return;
    }
    if (controller != null) {
      print("FREEING-ACTUAL-CONTROLLER, index: ${widget.index}");
      if (!_isInitializing) {
        print("FREEING-INITIALIZING, index: ${widget.index}");
        /*await*/ controller!.pause();
        //EVENT LISTENER RELATED JANK??
        if (controller!.eventListeners.isNotEmpty) {
          controller!.removeEventsListener(onPlayerEvent);
        }
        BpRegistryElem? elem = widget.videoListController!.getElem(controller!);
        widget.videoListController!.freeBetterPlayerController(elem);
        //TODO, NOTE: it is causing line 103 to throw null check operator error
        controller = null;
        if (!betterPlayerControllerStreamController.isClosed) {
          betterPlayerControllerStreamController.add(null);
        }
      } else {
        print("IS-INITIALIZING-FALSE, index: ${widget.index}");
        print("INIT-CONTROLLER: $controller, index: ${widget.index}");
        _isInitializing = false;
        _isWaiting = true;
      }
      //TODO: await a future that sets up controller, then set it to null?
    }
  }

  //JANK WHEN POPPING OUT / SCROLLING DOWN out of video
  //NOTE: all videos end up loading, OK
  Future<void> _freeAfterInitializing() async {
    //NOTE: instead, another video is played?
    //causes jank??
    print("FREEING-AFTER-INITIALIZING detected, index: ${widget.index}");
    if (controller != null) {
      print("CONTROLLER!=NULL, index: ${widget.index}");
      await controller!.pause();
      //NOTE: removeEventsListener?
      BpRegistryElem? elem = widget.videoListController!.getElem(controller!);
      widget.videoListController!.freeBetterPlayerController(elem);
      //TODO, NOTE: it is causing line 103 to throw null check operator error
      print("CONTROLLER-NULLED-PROPERLY, index: ${widget.index}");
      controller = null;
      if (!betterPlayerControllerStreamController.isClosed) {
        betterPlayerControllerStreamController.add(null);
      }
    } else {
      print("CONTROLLER-WAS-NULLED, index: ${widget.index}");
    }
    _isWaiting = false;
  }

  //TODO: check if received initialized video event
  Future<void> onPlayerEvent(BetterPlayerEvent event) async {
    print(
        "event received: ${event.betterPlayerEventType}, index: ${widget.index}");
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
  //NOTE: jank when rebuilding?? (see playwrongvideo.txt, line 176)
  @override
  Widget build(BuildContext context) {
    //SETSTATE(() {})??
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
                    if (!_isWaiting) {
                      await _freeController();
                    } else {
                      print("FREE-A, _isWaiting, index: ${widget.index}");
                    }
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
                if (!_isWaiting) {
                  await _freeController();
                } else {
                  print("FREE-B, _isWaiting, index: ${widget.index}");
                }
              }
              //jank reflects on logs
              //previous testings??
              //background playing??
              //auto-stopping??
            },
            //CONDITIONAL JANKING??
            // TODO: REMOVE ALL WIDGETS, LEAVE VIDEO ONLY AND SEE WHAT HAPPENS
            // TODO SEARCH, NOTE: THE MORE WIDGETS INSIDE STREAMBUILDER, THE LAGGIER?
            child: StreamBuilder<BetterPlayerController?>(
              stream: betterPlayerControllerStreamController.stream,
              builder: (context, snapshot) {
                print(
                    "CURR_INDEX: ${widget.index}, controller: $controller"); // wait for controller to be added to stream and then re-render
                // NOTE: widget tree optimized to render least children possible
                if (widget.render!) {
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
                            child: const Center(child: Text("Loading"))
                            //TODO: REMOVE CENTER?
                            //TODO: CALCULATE HOW MUCH OVERHEAD EACH WIDGET ADDS --> MIGHT BE INTERESTING

                            ),
                  );
                } else {
                  return /*Column(
                  children: [*/
                      //ADDING OVERHEAD??
                      AspectRatio(
                    aspectRatio: 16 / 9,
                    child: controller != null
                        ? const Text("Loaded")
                        : Container(
                            color: Colors.black,
                            child: const Center(child: Text("Loading"))
                            //TODO: REMOVE CENTER?
                            //TODO: CALCULATE HOW MUCH OVERHEAD EACH WIDGET ADDS --> MIGHT BE INTERESTING

                            ),
                  );
                }
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
