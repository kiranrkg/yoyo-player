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
import 'utils/utils.dart';
import 'widget/widget_bottombar.dart';
import '../yoyo_player.dart';
import 'event_player.dart';
import 'model/audio.dart';
import 'model/m3u8.dart';
import 'responses/regex_response.dart';
import 'widget/top_chip.dart';

typedef VideoCallback<T> = void Function(T t);

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

  /// show log of print
  final bool showLog;

  /// event player
  final EventPlayer event;

  /// show control
  final bool isShowControl;

  /// callback init completed
  final Function(VideoPlayerController) onInitCompleted;

  final bool isLooping;

  final bool showOptionM3U8;

  final bool autoHideOptionM3U8;
  final QuanlityVideo quanlity;

  final Function(QuanlityVideo) onChangeQuanlity;

  final StreamController<String> quanlityController;

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
    @required this.url,
    @required this.aspectRatio,
    @required this.quanlityController,
    this.event,
    this.videoStyle,
    this.videoLoadingStyle,
    this.onfullscreen,
    this.onpeningvideo,
    this.showLog = false,
    this.isShowControl = true,
    this.onInitCompleted,
    this.isLooping = true,
    this.showOptionM3U8 = false,
    this.autoHideOptionM3U8 = true,
    this.quanlity = QuanlityVideo.AUTO,
    this.onChangeQuanlity,
  }) : super(key: key);

  @override
  _YoYoPlayerState createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer>
    with SingleTickerProviderStateMixin {
  VideoPlayerController _videoController;
  // event player

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
  bool showMenu = false;
  // menu action
  bool showAction = false;
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

  QuanlityVideo currentQuanlity = QuanlityVideo.AUTO;

  void printLog(log) {
    if (widget.showLog) {
      final isPlaying = (_videoController?.value?.isPlaying ?? false)
          ? '[isPlaying:${_videoController.value.isPlaying}]'
          : '[Player Not Available]';
      // ignore: avoid_print
      print(
          "[YoYo Player][Controller:${_videoController != null}]$isPlaying $log");
    }
  }

  @override
  void initState() {
    printLog("-----------> initState <-----------");
    // getsub();
    currentQuanlity = widget.quanlity;
    urlcheck(widget.url);
    super.initState();

    /// Control bar animation
    controlBarAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    controlTopBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    controlBottomBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    final widgetsBinding = WidgetsBinding.instance;

    widgetsBinding.addPostFrameCallback((callback) {
      widgetsBinding.addPersistentFrameCallback((callback) {
        if (context == null) return;
        final orientation = MediaQuery.of(context).orientation;
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
    if (widget.event != null) {
      exportEventPlayer();
    }
    Screen.keepOn(true);
  }

  final Map<String, Function> listEventListener = {};
  void exportEventPlayer() {
    printLog("-----------> exportEventPlayer <-----------");
    widget.event.showOptionQuanlity = (ct) => showOptionQuanlity(ct);

    if (widget.event?.addListener != null) {
      widget.event
        ..addListener = (String key, Function event) {
          listEventListener[key] = event;
          _videoController?.addListener(listEventListener[key]);
        };
    }
    widget.event.play = () => actionWhenVideoActive(() async {
          createHideControlbarTimer();
          await _videoController.play();
          // _disableListener = false;
          if (mounted) {
            setState(() {});
          }
        });
    widget.event.pause = () => actionWhenVideoActive(() async {
          // _disableListener = true;
          createHideControlbarTimer();
          await _videoController.pause();
          if (mounted) {
            setState(() {});
          }
        });

    widget.event.isPlaying = _videoController?.value?.isPlaying ?? false;
    widget.event.isNotNull = _videoController != null &&
        (_videoController?.value?.initialized ?? false);
    widget.event.position = _videoController?.value?.duration;
    widget.event.aspectRatio = _videoController?.value?.aspectRatio;
    widget.event.updateQuanlity = (quanlity) {
      if (quanlity.toUpperCase() != m3u8quality.toUpperCase()) {
        widget.quanlityController.add(quanlity);
      }
    };
  }

  void actionWhenVideoActive(Function func) {
    printLog("-----------> actionWhenVideoActive <-----------");
    if (_videoController?.value?.initialized ?? false) {
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
      _videoController?.removeListener(listener);
      listEventListener.forEach((key, value) {
        _videoController?.removeListener(listEventListener[key]);
      });
      listEventListener.clear();
      _videoController?.dispose();
      _videoController = null;
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

    return StreamBuilder<String>(
      stream: widget.quanlityController.stream,
      builder: (context, snapshot) {
        if (snapshot?.data != null &&
            m3u8quality.toUpperCase() != snapshot.data) {
          m3u8quality = snapshot.data;
          m3u8show = false;
          currentQuanlity = quanlityType[snapshot.data];
          widget.onChangeQuanlity?.call(currentQuanlity);
          getCurrentQuanlity(yoyo, currentQuanlity).then((videoHLS) {
            onselectquality(videoHLS['info']);
          });
        }
        if (_videoController?.value?.initialized ?? false) {
          return renderVideo();
        }
        return widget.videoLoadingStyle.loading;
      },
    );
  }

  Widget renderVideo() {
    final videoChildrens = <Widget>[
      LayoutBuilder(builder: (context, constrain) {
        Widget _player = const SizedBox();

        if (_videoController?.value?.initialized ?? false) {
          if (_videoController.value.buffered?.isEmpty ?? true) {
            pauseVideo();
          }
          _player = VideoPlayer(_videoController);
        }

        return Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              toggleControls();
            },
            onDoubleTap: () {
              togglePlay();
            },
            child: _player,
          ),
        );
      }),
      if (widget.isShowControl) ...videoBuiltInChildrens()
    ];
    Widget body;
    if (fullscreen) {
      body = AspectRatio(
          aspectRatio: fullscreen
              ? calculateAspectRatio(context, screenSize)
              : _videoController?.value?.aspectRatio ?? 16 / 9,
          child: (_videoController?.value?.initialized ?? false)
              ? Stack(
                  children: videoChildrens,
                )
              : widget.videoLoadingStyle.loading);
    }
    body = AspectRatio(
      aspectRatio: _videoController?.value?.aspectRatio ?? 1,
      child: (_videoController?.value?.initialized ?? false)
          ? Stack(
              fit: StackFit.expand,
              children: videoChildrens,
            )
          : widget.videoLoadingStyle.loading,
    );

    return body;
  }

  /// Vieo Player ActionBar
  Widget actionBar() {
    printLog("-----------> actionBar <-----------");
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.only(top: !widget.autoHideOptionM3U8 ? 50 : 0),
        height: !widget.autoHideOptionM3U8 ? 200 : 40,
        width: double.infinity,
        // color: Colors.yellow,
        child: quanlityOption(),
      ),
    );
  }

  Widget quanlityOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 5,
        ),
        if ((widget.url?.contains?.call('m3u8') ?? false) &&
            widget.showOptionM3U8)
          topchip(
            context,
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Text(m3u8quality),
            ),
            () {
              m3u8show = true;
            },
          ),
        Container(
          width: 5,
        ),
      ],
    );
  }

  Widget m3u8list() {
    printLog("-----------> m3u8list <-----------");
    return m3u8show == true
        ? Align(
            alignment: !widget.autoHideOptionM3U8
                ? Alignment.topRight
                : Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                  top: !widget.autoHideOptionM3U8 ? 120 : 0,
                  bottom: !widget.autoHideOptionM3U8 ? 0 : 40,
                  right: 5),
              child: SingleChildScrollView(
                child: Column(
                  children: yoyo.map((e) {
                    final mathQuanlity = e.dataquality.split('x');
                    final quanlity = ((mathQuanlity?.length ?? 0) > 1)
                        ? mathQuanlity[1]
                        : e.dataquality;
                    final nameQuanlity = quanlityName[isResolution(quanlity)];
                    return InkWell(
                      onTap: () {
                        m3u8quality = nameQuanlity;
                        m3u8show = false;
                        widget.onChangeQuanlity?.call(isResolution(quanlity));
                        onselectquality(e);
                        widget.quanlityController.add(m3u8quality);
                        printLog(
                            "--- quality select ---\nquality : ${e.dataquality}\nlink : ${e.dataurl}");
                      },
                      child: Container(
                          width: 90,
                          color: m3u8quality == nameQuanlity
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).scaffoldBackgroundColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("$nameQuanlity"),
                          )),
                    );
                  }).toList(),
                ),
              ),
            ),
          )
        : Container();
  }

  List<Widget> videoBuiltInChildrens() {
    printLog("-----------> videoBuiltInChildrens <-----------");
    return [
      if ((_videoController?.value?.initialized ?? false) &&
          !widget.autoHideOptionM3U8 &&
          !_videoController.value.isPlaying)
        actionBar(),
      if (widget.autoHideOptionM3U8) btm(),
      if (_videoController?.value?.initialized ?? false) actionVideo(),
      m3u8list(),
    ];
  }

  Widget btm() {
    printLog("-----------> btm <-----------");
    return showMenu
        ? bottomBar(
            controller: _videoController,
            videoSeek: "$videoSeek",
            videoDuration: "$videoDuration",
            showMenu: showMenu,
            quanlity: quanlityOption(),
            play: () => togglePlay())
        : Container();
  }

  Widget actionVideo() {
    printLog("-----------> btm <-----------");
    return showMenu
        ? GestureDetector(
            onTap: togglePlay,
            child: Center(
              child: Icon(
                _videoController.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                size: 60,
                color: Colors.white,
              ),
            ),
          )
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
        printLog("urlend : m3u8 => $url");
        getm3u8(url).then((value) {
          getCurrentQuanlity(yoyo, currentQuanlity).then((videoHLS) {
            m3u8quality = quanlityName[videoHLS['type']];
            videoControllSetup(videoHLS['info'].dataurl);
          });
        });
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
  Future<void> getm3u8(String video) async {
    printLog("-----------> getm3u8 <-----------");
    if (yoyo.length > 0) {
      printLog("${yoyo.length} : data start clean");
      m3u8clean();
    }
    await m3u8video(video);
  }

  Future<void> m3u8video(String video) async {
    printLog("-----------> m3u8video <-----------");
    yoyo.add(M3U8pass(dataquality: "Auto", dataurl: video));
    final RegExp regExpAudio = new RegExp(
      Rexexresponse.regexMEDIA,
      caseSensitive: false,
      multiLine: true,
    );
    final RegExp regExp = new RegExp(
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
        final http.Response response = await http.get(video);
        if (response.statusCode == 200) {
          m3u8Content = utf8.decode(response.bodyBytes);
        }
      }

      final List<RegExpMatch> matches = regExp.allMatches(m3u8Content).toList();
      final List<RegExpMatch> audioMatches =
          regExpAudio.allMatches(m3u8Content).toList();
      printLog(
          "--- HLS Data ----\n$m3u8Content \ntotal length: ${yoyo.length} \nfinish");
      for (final itemInfo in matches) {
        await handleInfoVideo(itemInfo, video, audioMatches);
      }

      printLog(
          "--- m3u8 file write ---\n${yoyo.map((e) => e.dataquality == e.dataurl).toList()}\nlength : ${yoyo.length}\nSuccess");
    } catch (e) {
      printLog("-----> bug render video M3U8 $e");
    }
  }

  Future<void> handleInfoVideo(RegExpMatch regExpMatch, String video,
      List<RegExpMatch> audioMatches) async {
    final String quality = (regExpMatch.group(1)).toString();
    final String sourceurl = (regExpMatch.group(3)).toString();
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
    await audioMatches.forEach(
      (RegExpMatch regExpMatch2) async {
        final String audiourl = (regExpMatch2.group(1)).toString();
        final isNetwork = netRegx.hasMatch(audiourl);
        final match = netRegx2.firstMatch(video);
        var auurl = audiourl;
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
    var audio = "";
    printLog("-- audio ---\naudio list length :${audio.length}");
    if (audioList.isNotEmpty) {
      audio =
          """#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-medium",NAME="audio",AUTOSELECT=YES,DEFAULT=YES,CHANNELS="2",URI="${audioList.last.url}"\n""";
    } else {
      audio = "";
    }
    final directory = await getApplicationDocumentsDirectory();

    try {
      final file = File('${directory.path}/yoyo$quality.m3u8');
      await file.writeAsString(
          """#EXTM3U\n#EXT-X-INDEPENDENT-SEGMENTS\n$audio#EXT-X-STREAM-INF:CLOSED-CAPTIONS=NONE,BANDWIDTH=1469712,RESOLUTION=$quality,FRAME-RATE=30.000\n$url""");
      printLog("------>> write done ${directory.path}/yoyo$quality.m3u8");
    } catch (e) {
      printLog(
          "------>> Couldn't write file ${directory.path}/yoyo$quality.m3u8");
    }
    yoyo.add(M3U8pass(dataquality: quality, dataurl: url));
  }

// Video controller
  void videoControllSetup(String url) {
    printLog("-----------> videoControllSetup <----------- :: $url");
    if (_videoController?.value?.initialized ?? false) {
      _videoController?.removeListener?.call(listener);
      _videoController = null;
    }
    videoInit(url);
    _videoController.addListener(listener);
  }

// video Listener
  // Timer timeListenner;
  void listener() async {
    printLog("-----------> listener <-----------");
    if (isStopListener && !(_videoController.value.isPlaying ?? true)) return;
    // timeListenner ??= Timer(const Duration(milliseconds: 600), () async {

    //   // timeListenner = null;
    // });

    if ((_videoController?.value?.initialized ?? false) &&
        (_videoController?.value?.isPlaying ?? false)) {
      if (!await Wakelock.enabled) {
        await Wakelock.enable();
      }
      videoDuration =
          convertDurationToString(_videoController?.value?.duration);
      videoSeek = convertDurationToString(_videoController?.value?.position);
      videoSeekSecond =
          _videoController?.value?.position?.inSeconds?.toDouble();
      videoDurationSecond =
          _videoController?.value?.duration?.inSeconds?.toDouble();
      if (!mounted) return;
      setState(() {});
    } else {
      if (await Wakelock.enabled) {
        if (!mounted) return;
        setState(() {});
      }
    }
  }

  void createHideControlbarTimer() {
    printLog("-----------> createHideControlbarTimer <-----------");
    clearHideControlbarTimer();
    showTime = Timer(const Duration(milliseconds: 5000), () {
      if (_videoController != null &&
          (_videoController?.value?.isPlaying ?? false) &&
          showMenu) {
        setState(() {
          showMenu = false;
          m3u8show = false;
          controlBarAnimationController.reverse();
        });
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

    if (!showMenu) {
      showMenu = true;
      createHideControlbarTimer();
    } else {
      m3u8show = false;
      showMenu = false;
    }

    setState(() {
      if (showMenu) {
        controlBarAnimationController.forward();
      } else {
        controlBarAnimationController.reverse();
      }
    });
  }

  void togglePlay() {
    printLog("-----------> togglePlay <-----------");
    actionWhenVideoActive(() {
      createHideControlbarTimer();
      if (_videoController.value.isPlaying) {
        pauseVideo();
      } else {
        playVideo();
      }
      setState(() {});
    });
  }

  void videoInit(String url) {
    printLog("-----------> videoInit <-----------");
    if (offline == false) {
      printLog(
          "--- Player Status ---\nplay url : $url\noffline : $offline\n--- start playing –––");

      if (playtype == "MKV") {
        _videoController =
            VideoPlayerController.network(url, formatHint: VideoFormat.dash)
              ..setLooping(widget.isLooping)
              ..initialize().then((value) {
                pauseVideo();
                widget.onInitCompleted?.call(_videoController);
              });
      } else if (playtype == "HLS") {
        _videoController =
            VideoPlayerController.network(url, formatHint: VideoFormat.hls)
              ..setLooping(widget.isLooping)
              ..initialize().then((_) {
                setState(() => hasInitError = false);
                pauseVideo();
                widget.onInitCompleted?.call(_videoController);
              }).catchError((e) {
                hasInitError = true;
                if (mounted) {
                  setState(() {});
                }
              });
      } else {
        _videoController =
            VideoPlayerController.network(url, formatHint: VideoFormat.other)
              ..setLooping(widget.isLooping)
              ..initialize().then((value) {
                pauseVideo();
                widget.onInitCompleted?.call(_videoController);
              });
      }
    } else {
      printLog(
          "--- Player Status ---\nplay url : $url\noffline : $offline\n--- start playing –––");
      _videoController = VideoPlayerController.file(File(url))
        ..setLooping(widget.isLooping)
        ..initialize().then((value) {
          pauseVideo();
          widget.onInitCompleted?.call(_videoController);
          setState(() => hasInitError = false);
        }).catchError((e) => setState(() => hasInitError = true));
    }
  }

  String convertDurationToString(Duration duration) {
    printLog("-----------> convertDurationToString <-----------");
    final minutes = duration?.inMinutes?.toString() ?? '0';

    var seconds = ((duration?.inSeconds ?? 0) % 60).toString();
    if (seconds.length == 1) {
      seconds = "0$seconds";
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
    pauseVideo();
    if (data.dataquality == "Auto") {
      videoControllSetup(data.dataurl);
    } else {
      //puzuka
      try {
        if (Platform.isAndroid) {
          String text;
          final Directory directory = await getApplicationDocumentsDirectory();
          final File file =
              File('${directory.path}/yoyo${data.dataquality}.m3u8');
          printLog("read file success");
          text = await file.readAsString();
          printLog("data : $text  :: data");
          runFile(file);
        } else {
          videoControllSetup(data.dataurl);
        }
        // localm3u8play(data.dataurl);
      } catch (e) {
        printLog("Couldn't read file ${data.dataquality} e: $e");
      }
      printLog("data : ${data.dataquality}");
    }
  }

  bool isStopListener = false;
  void runFile(File file) {
    printLog("-----------> localm3u8play <-----------");

    _videoController = VideoPlayerController.file(file)
      ..setLooping(widget.isLooping)
      ..initialize().then((_) {
        pauseVideo();
        widget.onInitCompleted?.call(_videoController);
        setState(() => hasInitError = false);
      }).catchError((e) => setState(() => hasInitError = true));
    _videoController.addListener(listener);
  }

  void pauseVideo() {
    if (_videoController?.value?.initialized ?? false) {
      _videoController.pause();
    }
  }

  void playVideo() {
    if (_videoController?.value?.initialized ?? false) {
      _videoController.play();
    }
  }

  void m3u8clean() async {
    printLog("-----------> m3u8clean <-----------");
    printLog(yoyo.length);
    for (var i = 2; i < yoyo.length; i++) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${yoyo[i].dataquality}.m3u8');
        file?.delete()?.catchError((e) {
          printLog("delete error $file");
        })?.then((value) => printLog("delete success $file"));
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

  Future showOptionQuanlity(BuildContext ct) {
    return showDialog(
      context: ct,
      builder: (ct) {
        return AlertDialog(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          content: SingleChildScrollView(
            child: ListBody(
              children: yoyo.map((e) {
                final mathQuanlity = e.dataquality.split('x');
                final quanlity = ((mathQuanlity?.length ?? 0) > 1)
                    ? mathQuanlity[1]
                    : e.dataquality;
                final nameQuanlity = quanlityName[isResolution(quanlity)];
                return InkWell(
                  onTap: () {
                    m3u8quality = nameQuanlity;
                    m3u8show = false;
                    widget.onChangeQuanlity?.call(isResolution(quanlity));
                    onselectquality(e);
                    widget.quanlityController.add(m3u8quality);
                    printLog(
                        "--- quality select ---\nquality : ${e.dataquality}\nlink : ${e.dataurl}");
                    Navigator.of(context).pop(true);
                  },
                  child: Container(
                      decoration: yoyo.last != e
                          ? const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 0.5,
                                  color: Colors.white10,
                                ),
                              ),
                            )
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("$nameQuanlity"),
                          ),
                          Radio(
                            value: nameQuanlity,
                            groupValue: m3u8quality,
                            onChanged: (value) {
                              m3u8quality = value;
                            },
                          ),
                        ],
                      )),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
