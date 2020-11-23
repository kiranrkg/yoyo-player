import 'package:flutter/material.dart';

class EventPlayer {
  Function(String key, Function event) addListener;
  Future<bool> Function(String) updateQuality;
  Function(BuildContext) showOptionQuality;
  bool Function() isPlaying;
  Function() pause;
  Function() play;
  double Function() aspectRatio;
  Duration Function() position;
  bool Function() isNotNull;
}
