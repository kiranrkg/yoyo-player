import 'package:flutter/material.dart';

class EventPlayer {
  Function(String key, Function event) addListener;
  Function(String quanlity) updateQuanlity;
  Function(BuildContext) showOptionQuanlity;

  Function() pause;
  Function() play;
  double aspectRatio;
  Duration position;
  bool isPlaying;
  bool isNotNull;
}
