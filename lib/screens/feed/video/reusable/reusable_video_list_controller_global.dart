import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/services.dart';
import 'package:insta_feed/utils/video/reusable/bp_registry_elem.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';

//TOTAL 3 ERROR POSSIBILITIES: MEMORY CRASH, NO CONTROLLERS FREE IN LIST, NOT INITIALIZING
//EXOPLAYER
//TODO: internet connection loss results in controllers disappearing and not re-rendering
class ReusableVideoListControllerGlobal {
  final List<BpRegistryElem> _betterPlayerControllerRegistry = [];
  final List<BpRegistryElem> _usedBetterPlayerControllerRegistry = [];
  bool? autoplay;
  final Logger _logger = Logger();
  //TODO: check removing const
  BetterPlayerConfiguration? _config;

  List<BpRegistryElem> get getUsedBpRegistry =>
      _usedBetterPlayerControllerRegistry;

  BpRegistryElem? getElem(BetterPlayerController control) {
    return _usedBetterPlayerControllerRegistry.firstWhereOrNull((controller) {
      return control == controller.controller;
    });
  }

  //TODO, SEARCH: DO ALL ASYNC FUNCTIONS HAVE TO RETURN FUTURES??
  Future<void> onVisibilityChanged(double visibleFraction) async {
    print("Player visibility changed");
  }

  ReusableVideoListControllerGlobal(bool this.autoplay) {
    _config = BetterPlayerConfiguration(
      useRootNavigator: false, //true --> check out
      autoPlay: autoplay!, //true
      controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: true /*TODO: check*/,
          loadingWidget: Text("Hola"),
          showControlsOnInitialize: true /*--> false??*/),
      looping: false,
      fullScreenByDefault: false, //true
      aspectRatio: 16 / 9,
      autoDetectFullscreenDeviceOrientation: true,
      deviceOrientationsOnFullScreen: [DeviceOrientation.landscapeRight],
      //deviceOrientationsOnFullScreen: [DeviceOrientation.portraitUp],
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      //autoDetectFullscreenDeviceOrientation: true,
      //NOTE: was this the fail?
      autoDispose: false, //true
      //TODO, NOTE: SET HANDLELIFECYCLE TO LIBRARY
      handleLifecycle: false,
    );
    for (int index = 0; index < 3; index++) {
      _betterPlayerControllerRegistry.add(BpRegistryElem(
          BetterPlayerController(_config!), DateTime.now(), null));
    }
  }

  Future<void> onPlayerEvent(BetterPlayerEvent event) async {
    if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
      print("PROGRESS GLOBAL EVENT");
    }
    //TODO, CHECK: RECONNECT TO SURFACE LAG??
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      //CHECK FOR "NULL OPERATOR USED ON A NULL VALUE" ERROR --> pause video on disappear??
      print("INITIALIZED GLOBAL EVENT");
    }
    if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
      print("PAUSE GLOBAL EVENT");
    }
  }

  Future<int?> minDate(List<BpRegistryElem> list) async {
    int min = 0;
    int i = 0;
    Completer<int?> completer = Completer<int?>();
    for (BpRegistryElem bp in list) {
      if (bp.dt!.compareTo(list[min].dt!) /*> 0*/ <= 0) {
        min = i;
      }
      i++;
    }
    completer.complete(min);
    return completer.future;
  }

  // check if list contains element
  bool contains(BpRegistryElem element, List<BpRegistryElem> list) {
    for (BpRegistryElem e in list) {
      if (e.controller == element.controller) return true;
    }
    return false;
  }

  void printElems(List<BpRegistryElem> elems) {
    int i = 0;
    print("LIST_LENGTH: ${elems.length}");
    for (BpRegistryElem e in elems) {
      print("LIST_INDEX: $i, INDEX_CONTROLLER: ${e.index}");
      i++;
    }
  }

  // check if "elems" contains element of listView index "index"
  bool isIntruder(List<BpRegistryElem> elems, int index) {
    print("CHECKING_ELEM_AT_INDEX: $index");
    int i = 0;
    for (BpRegistryElem e in elems) {
      print("SEARCH_INDEX: $index, CURRENT_ELEMENT_INDEX: ${e.index}");
      if (index == e.index) {
        print("MATCHED");
        i++;
      }
    }
    //TODO, NOTE, ERROR: setting i > 1 sometimes gives wrong intruder (appears twice and not none), affects performance
    //a little tiny bit
    if (i < 1 /* || i > 1*/) {
      if (i == 0) {
        print("DOESNT APPEAR, INTRUDER @index: $index");
      } else {
        print("INDEX_APPEARS_MORE_THAN_ONCE");
      }
      return true;
    }
    return false;
  }

  Future<BetterPlayerController?> getBetterPlayerControllerReassign(
      int reassignIndex) async {
    //TODO: add future completer?
    //NOTE: if a video is unloaded and the one currently in center view is waiting to be loaded,
    //the unloaded one is going to be loaded with the same controller as the current one --> sometimes, not always
    //check if it also happens in a regular loading situation
    BpRegistryElem? freeController =
        _betterPlayerControllerRegistry.firstWhereOrNull((controller) {
      return !contains(controller, _usedBetterPlayerControllerRegistry);
      //return !_usedBetterPlayerControllerRegistry.contains(controller);
    });
    if (freeController == null) {
      print("FREECONTROLLER_IS_NULL");
      return null;
    }
    _usedBetterPlayerControllerRegistry.add(freeController);
    freeController.index = reassignIndex;
    return freeController.controller;
  }

  //ERROR: sometimes not loading right video but playing other video's audio when "Play" button is clicked
  //TODO: add timestamp?
  Future<BetterPlayerController?> getBetterPlayerController(
      [int? retrying, BetterPlayerController? retryController]) async {
    if (retryController != null) {
      print("FREEING_CONTROLLER_RETRYCONTROLLER!=NULL");
      BpRegistryElem? ctrl = //_betterPlayerControllerRegistry
          _usedBetterPlayerControllerRegistry.firstWhereOrNull(
              (controller) => controller.controller == retryController);
      freeBetterPlayerController(ctrl);
    }

    //TODO: add future completer?
    //NOTE: if a video is unloaded and the one currently in center view is waiting to be loaded,
    //the unloaded one is going to be loaded with the same controller as the current one --> sometimes, not always
    //check if it also happens in a regular loading situation
    BpRegistryElem? freeController =
        _betterPlayerControllerRegistry.firstWhereOrNull((controller) {
      print("CONTROLAZIONE: $controller, index: $retrying");
      if (retryController == null) {
        print("RETRYCONTROLLER==NULL");
        return !contains(controller, _usedBetterPlayerControllerRegistry);
        //return !_usedBetterPlayerControllerRegistry.contains(controller);
      } else {
        print("RETRYCONTROLLER!=NULL");
        return !contains(controller, _usedBetterPlayerControllerRegistry) &&
            controller.controller != retryController;
      }
    });
    //TODO: CHECK ALL CONTROLLER REGISTRIES LENGTH IS ALWAYS 3

    return freeController!.controller;
  }

  void freeBetterPlayerController(BpRegistryElem? betterPlayerController) {
    betterPlayerController?.index = null;
    //NOTE: duplicate controller issue possibly here
    //TODO: ADD FUTURE AND COMPLETER?
    _usedBetterPlayerControllerRegistry.remove(betterPlayerController);
  }

  void dispose() {
    _betterPlayerControllerRegistry.forEach((controller) {
      //NOTE: necessary to clearCache?
      //TODO: study line below
      controller.controller!.clearCache();
      controller.controller!.dispose(forceDispose: true);
    });
  }
}
