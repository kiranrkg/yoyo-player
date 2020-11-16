class EventPlayer {
  Function() play;
  Function() pause;
  Function() mute;
  Function() unmute;
  Function() dispose;
  Function(String key, Function event) addListener;

  bool isPlaying;
  bool notNullPlayer;
  Duration duration;
  double aspectRatio;
}
