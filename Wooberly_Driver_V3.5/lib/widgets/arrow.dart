import 'dart:math';

import 'package:flutter/material.dart';

class Arrow extends StatelessWidget {
  final Color color;

  Arrow({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20.0,
      width: 20.0,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: 20.0,
          maxHeight: 20.0,
          child: Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(.0, 5.0),
              child: Transform.rotate(
                angle: pi / 4,
                child: Container(
                  width: 10.0,
                  height: 10.0,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}