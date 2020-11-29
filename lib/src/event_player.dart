import 'package:flutter/material.dart';

class EventPlayer {
  Function(String key, Function event) addListener;
  Future<bool> Function(String) updateQuality;
  Function(BuildContext) showOptionQuality;
  bool Function() isPlaying;
  Future<void> Function() pause;
  Function() play;
  double Function() aspectRatio;
  StatePlayer Function() statePlayer;
  Duration Function() position;
  bool Function() isNotNull;
}

enum StatePlayer { init, unknown, running, error, stop }
enum StateErrorPlayer { init, running, stop, none }
