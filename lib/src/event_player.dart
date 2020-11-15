class EventPlayer {
  static EventPlayer instance;

  Function() play;
  Function() pause;
  Function() mute;
  Function() unmute;
  bool isPlaying;
  bool notNullPlayer;

  factory EventPlayer() {
    if (instance == null) instance = EventPlayer._internal();
    return instance;
  }
  EventPlayer._internal();
}