import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orientation/orientation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import 'package:http/http.dart' as http;
import 'package:yoyo_player/src/utils/utils.dart';
import 'package:yoyo_player/src/widget/widget_bottombar.dart';
import '../yoyo_player.dart';
import 'event_player.dart';
import 'model/audio.dart';
import 'model/m3u8.dart';
import 'model/m3u8s.dart';
import 'responses/regex_response.dart';
import 'widget/top_chip.dart';

typedef VideoCallback<T> = void Function(T t);

class YoyoPlayerController {
  VideoPlayerController controller;
  YoyoPlayerController(this.controller);
}

class YoYoPlayer extends StatefulWidget {
  ///Video[source],
  ///```dart
  ///url:"https://example.com/index.m3u8";
  ///```
  final String url;

  ///Video Player  style
  ///```dart
  ///videoStyle : VideoStyle(
  ///     play =  Icon(Icons.play_arrow),
  ///     pause = Icon(Icons.pause),
  ///     fullscreen =  Icon(Icons.fullscreen),
  ///     forward =  Icon(Icons.skip_next),
  ///     backward =  Icon(Icons.skip_previous),
  ///     playedColor = Colors.green,
  ///     qualitystyle = const TextStyle(
  ///     color: Colors.white,),
  ///      qashowstyle = const TextStyle(
  ///      color: Colors.white,
  ///    ),
  ///   );
  ///```
  final VideoStyle videoStyle;

  /// Video Loading Style
  final VideoLoadingStyle videoLoadingStyle;

  /// Video AspectRaitio [aspectRatio : 16 / 9 ]
  final double aspectRatio;

  /// video state fullscreen
  final VideoCallback<bool> onfullscreen;

  /// video Type
  final VideoCallback<String> onpeningvideo;

  // Vieo Player Controller
  final YoyoPlayerController yoyoController;

  final bool showLog;

  ///
  /// ```dart
  /// YoYoPlayer(
  /// //url = (m3u8[hls],.mp4,.mkv,)
  ///   url : "",
  /// //video style
  ///   videoStyle : VideoStyle(),
  /// //video loading style
  ///   videoLoadingStyle : VideoLoadingStyle(),
  /// //video aspet ratio
  ///   aspectRatio : 16/9,
  /// )
  /// ```
  YoYoPlayer({
    Key key,
    @required this.yoyoController,
    @required this.url,
    @required this.aspectRatio,
    this.videoStyle,
    this.videoLoadingStyle,
    this.onfullscreen,
    this.onpeningvideo,
    this.showLog = false,
  }) : super(key: key);

  @override
  _YoYoPlayerState createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer>
    with SingleTickerProviderStateMixin {
  VideoPlayerController controller;
  // event player
  final EventPlayer _event = EventPlayer();
  //vieo play type (hls,mp4,mkv,offline)
  String playtype;
  // Animation Controller
  AnimationController controlBarAnimationController;
  // Video Top Bar Animation
  Animation<double> controlTopBarAnimation;
  // Video Bottom Bar Animation
  Animation<double> controlBottomBarAnimation;
  // Video init error defult :false
  bool hasInitError = false;
  // Video Total Time duration
  String videoDuration;
  // Viedo Seed to
  String videoSeek;
  // Video dutarion 1
  Duration duration;
  // video seek second by user
  double videoSeekSecond;
  // video vuration second
  double videoDurationSecond;
  //m3u8 data video list for user chooice
  List<M3U8pass> yoyo = List();
  // m3u8 audio list
  List<AUDIO> audioList = List();
  // m3u8 temp data
  String m3u8Content;
  // subtitle temp data
  String subtitleContent;
  // menu show m3u8 list
  bool m3u8show = false;
  // video full screen
  bool fullscreen = false;
  // menu show
  bool showMeau = false;
  // auto show subtitle
  bool showSubtitles = false;
  // video status
  bool offline;
  // video auto quality
  String m3u8quality = "Auto";
  // time for duration
  Timer showTime;
  //Current ScreenSize
  Size get screenSize => MediaQuery.of(context).size;
  bool _disableListener = false;

  void printLog(log) {
    if (widget.showLog) {
      final isPlaying = (controller?.value?.isPlaying ?? false)
          ? '[isPlaying:${controller.value.isPlaying}]'
          : '[Player Not Available]';
      print("[YoYo Player][Controller:${controller != null}]$isPlaying $log");
    }
  }

  @override
  void initState() {
    printLog("-----------> initState <-----------");
    // getsub();
    urlcheck(widget.url);
    super.initState();

    /// Control bar animation
    controlBarAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    controlTopBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    controlBottomBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    var widgetsBinding = WidgetsBinding.instance;

    widgetsBinding.addPostFrameCallback((callback) {
      widgetsBinding.addPersistentFrameCallback((callback) {
        if (context == null) return;
        var orientation = MediaQuery.of(context).orientation;
        bool _fullscreen;
        if (orientation == Orientation.landscape) {
          //Horizontal screen
          _fullscreen = true;
          SystemChrome.setEnabledSystemUIOverlays([]);
        } else if (orientation == Orientation.portrait) {
          _fullscreen = false;
          SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
        }
        if (_fullscreen != fullscreen) {
          setState(() {
            fullscreen = !fullscreen;
            _navigateLocally(context);
            if (widget.onfullscreen != null) {
              widget.onfullscreen(fullscreen);
            }
          });
        }
        //
        widgetsBinding.scheduleFrame();
      });
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    exportEventPlayer();
    Screen.keepOn(true);
  }

  void exportEventPlayer() {
    printLog("-----------> exportEventPlayer <-----------");
    _event.play = () => actionWhenVideoActive(() {
          createHideControlbarTimer();
          print("----------->> Play Vide");
          controller?.play();
          _disableListener = false;
          if (mounted) {
            setState(() {});
          }
        });
    _event.pause = () => actionWhenVideoActive(() {
          _disableListener = true;
          createHideControlbarTimer();
          print("----------->> Pause Vide");
          controller?.pause();
          if (mounted) {
            setState(() {});
          }
        });
    _event.mute = () => actionWhenVideoActive(() => controller.setVolume(0));
    _event.unmute = () => actionWhenVideoActive(() => controller.setVolume(1));

    _event.dispose = disposeVideo;
    _event.isPlaying = controller?.value?.isPlaying ?? false;
    _event.notNullPlayer =
        controller != null && (controller?.value?.initialized ?? false);
  }

  void actionWhenVideoActive(Function func) {
    printLog("-----------> actionWhenVideoActive <-----------");
    if (controller?.value?.initialized ?? false) {
      printLog("-----------> Active");
      func?.call();
    } else {
      printLog("-----------> Deactive");
    }
  }

  void disposeVideo() {
    printLog("-----------> disposeVideo <-----------");
    m3u8clean();
    actionWhenVideoActive(() {
      controller?.removeListener(listener);
      controller?.dispose();
      controller = null;
    });
  }

  @override
  void dispose() {
    printLog("-----------> dispose <-----------");
    disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    printLog("-----------> build <-----------");
    final videoChildrens = <Widget>[
      GestureDetector(
        onTap: () {
          toggleControls();
        },
        onDoubleTap: () {
          togglePlay();
        },
        child: AspectRatio(
          aspectRatio: controller?.value?.aspectRatio ?? 16 / 9,
          child: VideoPlayer(controller),
        ),
      ),
    ];
    videoChildrens.addAll(videoBuiltInChildrens());
    return AspectRatio(
      aspectRatio: fullscreen
          ? calculateAspectRatio(context, screenSize)
          : widget.aspectRatio ?? 16 / 9,
      child: (controller?.value?.initialized ?? false)
          ? Stack(children: videoChildrens)
          : widget.videoLoadingStyle.loading,
    );
  }

  /// Vieo Player ActionBar
  Widget actionBar() {
    printLog("-----------> actionBar <-----------");
    return showMeau
        ? Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 40,
              width: double.infinity,
              // color: Colors.yellow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 5,
                  ),
                  topchip(
                    Text(m3u8quality, style: widget.videoStyle.qualitystyle),
                    () {
                      // quality function
                      m3u8show = true;
                    },
                  ),
                  Container(
                    width: 5,
                  ),
                  InkWell(
                    onTap: () => toggleFullScreen(),
                    child: Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 5,
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  Widget m3u8list() {
    printLog("-----------> m3u8list <-----------");
    return m3u8show == true
        ? Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0, right: 5),
              child: SingleChildScrollView(
                child: Column(
                  children: yoyo
                      .map((e) => InkWell(
                            onTap: () {
                              m3u8quality = e.dataquality;
                              m3u8show = false;
                              onselectquality(e);
                              printLog(
                                  "--- quality select ---\nquality : ${e.dataquality}\nlink : ${e.dataurl}");
                            },
                            child: Container(
                                width: 90,
                                color: Colors.grey,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${e.dataquality}",
                                    style: widget.videoStyle.qashowstyle,
                                  ),
                                )),
                          ))
                      .toList(),
                ),
              ),
            ),
          )
        : Container();
  }

  List<Widget> videoBuiltInChildrens() {
    printLog("-----------> videoBuiltInChildrens <-----------");
    return [
      actionBar(),
      btm(),
      m3u8list(),
    ];
  }

  Widget btm() {
    printLog("-----------> btm <-----------");
    return showMeau
        ? bottomBar(
            controller: controller,
            videoSeek: "$videoSeek",
            videoDuration: "$videoDuration",
            showMeau: showMeau,
            play: () => togglePlay())
        : Container();
  }

  void urlcheck(String url) {
    printLog("-----------> urlcheck <-----------");
    final netRegx = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
    final isNetwork = netRegx.hasMatch(url);
    final a = Uri.parse(url);

    printLog("parse url data end : ${a.pathSegments.last}");
    if (isNetwork) {
      setState(() {
        offline = false;
      });
      if (a.pathSegments.last.endsWith("mkv")) {
        if (widget.onpeningvideo == null) {
          setState(() {
            playtype = "MKV";
          });
          printLog("urlend : mkv");
          // widget.onpeningvideo("MKV");
        }
        videoControllSetup(url);
      } else if (a.pathSegments.last.endsWith("mp4")) {
        if (widget.onpeningvideo == null) {
          setState(() {
            playtype = "MP4";
          });
          printLog("urlend : mp4 $playtype");
          // widget.onpeningvideo("MP4");
        }
        printLog("urlend : mp4");
        videoControllSetup(url);
      } else if (a.pathSegments.last.endsWith("m3u8")) {
        if (widget.onpeningvideo == null) {
          setState(() {
            playtype = "HLS";
          });
          // widget.onpeningvideo("M3U8");
        }
        printLog("urlend : m3u8");
        videoControllSetup(url);
        getm3u8(url);
      } else {
        printLog("urlend : null");
        videoControllSetup(url);
        getm3u8(url);
      }
      printLog("--- Current Video Status ---\noffline : $offline");
    } else {
      setState(() {
        offline = true;
        printLog(
            "--- Current Video Status ---\noffline : $offline \n --- :3 done url check ---");
      });
      videoControllSetup(url);
    }
  }

// M3U8 Data Setup
  void getm3u8(String video) {
    printLog("-----------> getm3u8 <-----------");
    if (yoyo.length > 0) {
      printLog("${yoyo.length} : data start clean");
      m3u8clean();
    }
    printLog("---- m3u8 fesh start ----\n$video\n--- please wait –––");
    m3u8video(video);
  }

  Future<M3U8s> m3u8video(String video) async {
    printLog("-----------> m3u8video <-----------");
    yoyo.add(M3U8pass(dataquality: "Auto", dataurl: video));
    RegExp regExpAudio = new RegExp(
      Rexexresponse.regexMEDIA,
      caseSensitive: false,
      multiLine: true,
    );
    RegExp regExp = new RegExp(
      r"#EXT-X-STREAM-INF:(?:.*,RESOLUTION=(\d+x\d+))?,?(.*)\r?\n(.*)",
      caseSensitive: false,
      multiLine: true,
    );
    setState(
      () {
        if (m3u8Content != null) {
          printLog("--- HLS Old Data ----\n$m3u8Content");
          m3u8Content = null;
        }
      },
    );
    try {
      if (m3u8Content == null && video != null) {
        http.Response response = await http.get(video);
        if (response.statusCode == 200) {
          m3u8Content = utf8.decode(response.bodyBytes);
        }
      }
      print("======> m3u8Content: $m3u8Content");

      List<RegExpMatch> matches = regExp.allMatches(m3u8Content).toList();
      List<RegExpMatch> audioMatches =
          regExpAudio.allMatches(m3u8Content).toList();
      printLog(
          "--- HLS Data ----\n$m3u8Content \ntotal length: ${yoyo.length} \nfinish");

      matches.forEach(
        (RegExpMatch regExpMatch) async {
          String quality = (regExpMatch.group(1)).toString();
          String sourceurl = (regExpMatch.group(3)).toString();
          final netRegx = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
          final netRegx2 = new RegExp(r'(.*)\r?\/');
          final isNetwork = netRegx.hasMatch(sourceurl);
          final match = netRegx2.firstMatch(video);
          String url;
          if (isNetwork) {
            url = sourceurl;
          } else {
            printLog(match);
            final dataurl = match.group(0);
            url = "$dataurl$sourceurl";
            printLog("--- hls chlid url intergration ---\nchild url :$url");
          }
          audioMatches.forEach(
            (RegExpMatch regExpMatch2) async {
              String audiourl = (regExpMatch2.group(1)).toString();
              final isNetwork = netRegx.hasMatch(audiourl);
              final match = netRegx2.firstMatch(video);
              String auurl = audiourl;
              if (isNetwork) {
                auurl = audiourl;
              } else {
                printLog(match);
                final audataurl = match.group(0);
                auurl = "$audataurl$audiourl";
                printLog("url network audio  $url $audiourl");
              }
              audioList.add(AUDIO(url: auurl));
              printLog(audiourl);
            },
          );
          String audio = "";
          printLog("-- audio ---\naudio list length :${audio.length}");
          if (audioList.length != 0) {
            audio =
                """#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-medium",NAME="audio",AUTOSELECT=YES,DEFAULT=YES,CHANNELS="2",URI="${audioList.last.url}"\n""";
          } else {
            audio = "";
          }
          try {
            final Directory directory =
                await getApplicationDocumentsDirectory();
            final File file = File('${directory.path}/yoyo$quality.m3u8');
            await file.writeAsString(
                """#EXTM3U\n#EXT-X-INDEPENDENT-SEGMENTS\n$audio#EXT-X-STREAM-INF:CLOSED-CAPTIONS=NONE,BANDWIDTH=1469712,RESOLUTION=$quality,FRAME-RATE=30.000\n$url""");
          } catch (e) {
            printLog("Couldn't write file");
          }
          yoyo.add(M3U8pass(dataquality: quality, dataurl: url));
        },
      );
      M3U8s m3u8s = M3U8s(m3u8s: yoyo);
      printLog(
          "--- m3u8 file write ---\n${yoyo.map((e) => e.dataquality == e.dataurl).toList()}\nlength : ${yoyo.length}\nSuccess");
      return m3u8s;
    } catch (e) {
      printLog("-----> bug render video M3U8 $e");
    }
    return null;
  }

// Video controller
  void videoControllSetup(String url) {
    printLog("-----------> videoControllSetup <-----------");
    videoInit(url);
    controller.addListener(listener);
    controller.play();
  }

// video Listener
  Timer timeListenner;
  void listener() async {
    if (_disableListener) return;
    printLog("-----------> listener <-----------");
    if (timeListenner == null) {
      timeListenner = Timer(Duration(milliseconds: 600), () async {
        if ((controller?.value?.initialized ?? false) &&
            (controller?.value?.isPlaying ?? false)) {
          if (!await Wakelock.enabled) {
            await Wakelock.enable();
          }
          videoDuration = convertDurationToString(controller?.value?.duration);
          videoSeek = convertDurationToString(controller?.value?.position);
          videoSeekSecond = controller?.value?.position?.inSeconds?.toDouble();
          videoDurationSecond =
              controller?.value?.duration?.inSeconds?.toDouble();
          if (!mounted) return;
          setState(() {});
        } else {
          if (await Wakelock.enabled) {
            if (!mounted) return;
            setState(() {});
          }
        }
        timeListenner = null;
      });
    }
  }

  void createHideControlbarTimer() {
    printLog("-----------> createHideControlbarTimer <-----------");
    clearHideControlbarTimer();
    showTime = Timer(Duration(milliseconds: 5000), () {
      if (controller != null && controller?.value?.isPlaying) {
        if (showMeau) {
          setState(() {
            showMeau = false;
            m3u8show = false;
            controlBarAnimationController.reverse();
          });
        }
      }
    });
  }

  void clearHideControlbarTimer() {
    printLog("-----------> clearHideControlbarTimer <-----------");
    showTime?.cancel();
  }

  void toggleControls() {
    printLog("-----------> toggleControls <-----------");
    clearHideControlbarTimer();

    if (!showMeau) {
      showMeau = true;
      createHideControlbarTimer();
    } else {
      m3u8show = false;
      showMeau = false;
    }

    setState(() {
      if (showMeau) {
        controlBarAnimationController.forward();
      } else {
        controlBarAnimationController.reverse();
      }
    });
  }

  void togglePlay() {
    printLog("-----------> togglePlay <-----------");
    createHideControlbarTimer();
    if (controller?.value?.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  void videoInit(String url) {
    printLog("-----------> videoInit <-----------");
    if (offline == false) {
      printLog(
          "--- Player Status ---\nplay url : $url\noffline : $offline\n--- start playing –––");

      if (playtype == "MKV") {
        controller =
            VideoPlayerController.network(url, formatHint: VideoFormat.dash)
              ..initialize();
      } else if (playtype == "HLS") {
        controller =
            VideoPlayerController.network(url, formatHint: VideoFormat.hls)
              ..initialize()
                  .then((_) => setState(() => hasInitError = false))
                  .catchError((e) => setState(() => hasInitError = true));
      } else {
        controller =
            VideoPlayerController.network(url, formatHint: VideoFormat.other)
              ..initialize();
      }
    } else {
      printLog(
          "--- Player Status ---\nplay url : $url\noffline : $offline\n--- start playing –––");
      controller = VideoPlayerController.file(File(url))
        ..initialize()
            .then((value) => setState(() => hasInitError = false))
            .catchError((e) => setState(() => hasInitError = true));
    }
  }

  String convertDurationToString(Duration duration) {
    printLog("-----------> convertDurationToString <-----------");
    var minutes = duration?.inMinutes?.toString() ?? '0';
    if (minutes.length == 1) {
      minutes = '0' + minutes;
    }
    var seconds = ((duration?.inSeconds ?? 0) % 60).toString();
    if (seconds.length == 1) {
      seconds = '0' + seconds;
    }
    return "$minutes:$seconds";
  }

  void _navigateLocally(context) async {
    printLog("-----------> _navigateLocally <-----------");
    if (!fullscreen) {
      if (ModalRoute.of(context).willHandlePopInternally) {
        Navigator.of(context).pop();
      }
      return;
    }
    ModalRoute.of(context).addLocalHistoryEntry(LocalHistoryEntry(onRemove: () {
      if (fullscreen) toggleFullScreen();
    }));
  }

  void onselectquality(M3U8pass data) async {
    printLog("-----------> onselectquality <-----------");
    controller.pause();
    if (data.dataquality == "Auto") {
      videoControllSetup(data.dataurl);
    } else {
      try {
        String text;
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file =
            File('${directory.path}/yoyo${data.dataquality}.m3u8');
        printLog("read file success");
        text = await file.readAsString();
        printLog("data : $text  :: data");
        localm3u8play(file);
        // videoControllSetup(file);
      } catch (e) {
        printLog("Couldn't read file ${data.dataquality} e: $e");
      }
      printLog("data : ${data.dataquality}");
    }
  }

  void localm3u8play(File file) {
    printLog("-----------> localm3u8play <-----------");
    controller = VideoPlayerController.file(
      file,
    )..initialize()
        .then((_) => setState(() => hasInitError = false))
        .catchError((e) => setState(() => hasInitError = true));
    controller.addListener(listener);
    controller.play();
  }

  void m3u8clean() async {
    printLog("-----------> m3u8clean <-----------");
    printLog(yoyo.length);
    for (int i = 2; i < yoyo.length; i++) {
      try {
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file = File('${directory.path}/${yoyo[i].dataquality}.m3u8');
        file.delete();
        printLog("delete success $file");
      } catch (e) {
        printLog("Couldn't delete file $e");
      }
    }
    try {
      printLog("Audio m3u8 list clean");
      audioList.clear();
    } catch (e) {
      printLog("Audio list clean error $e");
    }
    audioList.clear();
    try {
      printLog("m3u8 data list clean");
      yoyo.clear();
    } catch (e) {
      printLog("m3u8 video list clean error $e");
    }
  }

  void toggleFullScreen() {
    printLog("-----------> toggleFullScreen <-----------");
    if (fullscreen) {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    } else {
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
    }
  }

  void triggerMounted() {
    if (!mounted) return;
  }
}
