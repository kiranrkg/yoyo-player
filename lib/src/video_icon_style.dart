import 'package:flutter/material.dart';

/// Video Player Icon style
class VideoIconStyle {
  VideoIconStyle({
    this.play = Icons.play_arrow,
    this.pause = Icons.play_arrow,
    this.fullscreen = Icons.play_arrow,
    this.forward = Icons.skip_next,
    this.backward = Icons.skip_previous,

  });

  final IconData play;
  final IconData pause;
  final IconData fullscreen;
  final IconData forward;
  final IconData backward;
}