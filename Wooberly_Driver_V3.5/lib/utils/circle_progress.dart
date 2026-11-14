import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

class CircleProgress extends CustomPainter {
  double currentProgress;

  CircleProgress(this.currentProgress);

  @override
  void paint(Canvas canvas, Size size) {
    Paint outerCircle = Paint()
      ..strokeWidth = 5
      ..color = AppColors.BORDERCOLOR
      ..style = PaintingStyle.stroke;

    Paint completeArc = Paint()
      ..strokeWidth = 6
      ..color = AppColors.TripTRequest_TimerLoadColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2) - 10;

    canvas.drawCircle(
        center, radius, outerCircle);

    double angle =
        2 * pi * (currentProgress / globals.progressLoadTime.toDouble());

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2,
        angle, false, completeArc);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}