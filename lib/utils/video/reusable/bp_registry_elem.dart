import 'package:better_player/better_player.dart';

class BpRegistryElem {
  BetterPlayerController? controller;
  DateTime? dt;
  int? index;
  BpRegistryElem(BetterPlayerController bp, DateTime dateTime, int? ind) {
    controller = bp;
    dt = dateTime;
    index = ind;
  }
}
