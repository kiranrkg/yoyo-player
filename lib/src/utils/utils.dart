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
  final quanlity = int.parse(resolution);

  if (quanlity > 699) {
    return "HIGH";
  }
  if (quanlity > 599) {
    return "MEDIUM";
  }
  if (quanlity > 399) {
    return "LOW";
  }
  return "UNKNOWN";
}

QuanlityVideo getTypeResolution(String resolution) {
  if (resolution.toUpperCase() == "AUTO") {
    return QuanlityVideo.AUTO;
  }
  final quanlity = int.parse(resolution);

  if (quanlity > 699) {
    return QuanlityVideo.HIGH;
  }
  if (quanlity > 499) {
    return QuanlityVideo.MEDIUM;
  }
  if (quanlity < 499) {
    return QuanlityVideo.LOW;
  }
  return QuanlityVideo.UNKNOWN;
}

enum QuanlityVideo { AUTO, HIGH, MEDIUM, LOW, UNKNOWN }

Map quanlityName = {
  QuanlityVideo.HIGH: "HIGH",
  QuanlityVideo.MEDIUM: "MEDIUM",
  QuanlityVideo.LOW: "LOW",
  QuanlityVideo.AUTO: "AUTO",
  QuanlityVideo.UNKNOWN: "UNKNOWN",
};

Map quanlityType = {
  "HIGH": QuanlityVideo.HIGH,
  "MEDIUM": QuanlityVideo.MEDIUM,
  "LOW": QuanlityVideo.LOW,
  "AUTO": QuanlityVideo.AUTO,
  "UNKNOWN": QuanlityVideo.UNKNOWN,
};

QuanlityVideo getQuanlity(String nameQuanlity) =>
    quanlityType[nameQuanlity.toUpperCase()];

QuanlityVideo isResolution(String resolution) {
  if (resolution.toUpperCase() == "AUTO".toUpperCase()) {
    return QuanlityVideo.AUTO;
  }
  final quanlity = int.parse(resolution);

  if (quanlity > 699) {
    return QuanlityVideo.HIGH;
  }
  if (quanlity > 499) {
    return QuanlityVideo.MEDIUM;
  }
  if (quanlity < 499) {
    return QuanlityVideo.LOW;
  }
  return QuanlityVideo.UNKNOWN;
}

Future<Map> getCurrentQuanlity(
    List<M3U8pass> listQuanlity, QuanlityVideo currentQuanlity) async {
  Map result;
  final itemDefault = listQuanlity.first;
  final mathQuanlity = itemDefault.dataquality.split('x');
  final quanlityDefault = ((mathQuanlity?.length ?? 0) > 1)
      ? mathQuanlity[1]
      : itemDefault.dataquality;
  final resultAuto = {
    'info': itemDefault,
    'type': isResolution(quanlityDefault),
  };
  for (final item in listQuanlity) {
    final mathQuanlity = item.dataquality.split('x');
    final quanlity =
        ((mathQuanlity?.length ?? 0) > 1) ? mathQuanlity[1] : item.dataquality;
    final _currentQuanlity = isResolution(quanlity);

    if (_currentQuanlity == currentQuanlity) {
      result = {
        'info': item,
        'type': _currentQuanlity,
      };
      break;
    }
  }

  return result ?? resultAuto;
}
//1605742962252-
