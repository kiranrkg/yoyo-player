import 'package:flutter/material.dart';
import '../model/m3u8.dart';

double calculateAspectRatio(BuildContext context, Size screenSize) {
  final width = screenSize.width;
  final height = screenSize.height;
  // return widget.playOptions.aspectRatio ?? controller.value.aspectRatio;
  return width > height ? width / height : height / width;
}

String getNameResolution(String resolution) {
  if (resolution.toUpperCase() == "AUTO") {
    return "AUTO";
  }
  final quality = int.parse(resolution);

  if (quality > 699) {
    return "HIGH";
  }
  if (quality > 599) {
    return "MEDIUM";
  }
  if (quality > 399) {
    return "LOW";
  }
  return "UNKNOWN";
}

QualityVideo getTypeResolution(String resolution) {
  if (resolution.toUpperCase() == "AUTO") {
    return QualityVideo.AUTO;
  }
  final quality = int.parse(resolution);

  if (quality > 699) {
    return QualityVideo.HIGH;
  }
  if (quality > 499) {
    return QualityVideo.MEDIUM;
  }
  if (quality < 499) {
    return QualityVideo.LOW;
  }
  return QualityVideo.UNKNOWN;
}

enum QualityVideo { AUTO, HIGH, MEDIUM, LOW, UNKNOWN }

Map qualityName = {
  QualityVideo.HIGH: "HIGH",
  QualityVideo.MEDIUM: "MEDIUM",
  QualityVideo.LOW: "LOW",
  QualityVideo.AUTO: "AUTO",
  QualityVideo.UNKNOWN: "UNKNOWN",
};

Map qualityType = {
  "HIGH": QualityVideo.HIGH,
  "MEDIUM": QualityVideo.MEDIUM,
  "LOW": QualityVideo.LOW,
  "AUTO": QualityVideo.AUTO,
  "UNKNOWN": QualityVideo.UNKNOWN,
};

QualityVideo getQuality(String nameQuality) =>
    qualityType[nameQuality.toUpperCase()];

QualityVideo isResolution(String resolution) {
  if (resolution.toUpperCase() == "AUTO".toUpperCase()) {
    return QualityVideo.AUTO;
  }
  final quality = int.parse(resolution);

  if (quality > 699) {
    return QualityVideo.HIGH;
  }
  if (quality > 499) {
    return QualityVideo.MEDIUM;
  }
  if (quality < 499) {
    return QualityVideo.LOW;
  }
  return QualityVideo.UNKNOWN;
}

Future<Map> getCurrentQuality(
    List<M3U8pass> listQuality, QualityVideo currentQuality) async {
  Map result;
  final itemDefault = listQuality.first;
  final mathQuality = itemDefault.dataquality.split('x');
  final qualityDefault = ((mathQuality?.length ?? 0) > 1)
      ? mathQuality[1]
      : itemDefault.dataquality;
  final resultAuto = {
    'info': itemDefault,
    'type': isResolution(qualityDefault),
  };
  for (final item in listQuality) {
    final mathQuality = item.dataquality.split('x');
    final quality =
        ((mathQuality?.length ?? 0) > 1) ? mathQuality[1] : item.dataquality;
    final _currentQuality = isResolution(quality);

    if (_currentQuality == currentQuality) {
      result = {
        'info': item,
        'type': _currentQuality,
      };
      break;
    }
  }

  return result ?? resultAuto;
}
//1605742962252-
