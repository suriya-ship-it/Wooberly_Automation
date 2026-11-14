import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/routes/circular_reveal_clipper.dart';


class CircularRevealAnimation extends StatelessWidget {
  final Alignment? centerAlignment;
  final Offset? centerOffset;
  final double? minRadius;
  final double? maxRadius;
  final Widget child;
  final Animation<double> animation;

  final bool sustainClip;

  CircularRevealAnimation({
    required this.child,
    required this.animation,
    this.centerAlignment,
    this.centerOffset,
    this.minRadius,
    this.maxRadius,
    this.sustainClip = false,
  }) : assert(centerAlignment == null || centerOffset == null);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return ClipPath(
          clipBehavior:
          !sustainClip && animation.value == 1 ? Clip.none : Clip.antiAlias,
          clipper: CircularRevealClipper(
            fraction: animation.value,
            centerAlignment: centerAlignment,
            centerOffset: centerOffset,
            minRadius: minRadius,
            maxRadius: maxRadius,
          ),
          child: child,
        );
      },
      child: this.child,
    );
  }
}