import 'package:flutter/material.dart';

class EventPlayer {
  Function(String key, Function event) addListener;
  Future<bool> Function(String) updateQuanlity;
  Function(BuildContext) showOptionQuanlity;
  bool Function() isPlaying;

  Function() pause;
  Function() play;
  double aspectRatio;
  Duration position;

  bool isNotNull;
}
