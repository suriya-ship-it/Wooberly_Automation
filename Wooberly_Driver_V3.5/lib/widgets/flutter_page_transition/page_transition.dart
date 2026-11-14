library page_transition;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

class PageTransition<T> extends PageRouteBuilder<T> {
  final Widget? child;

  final PageTransitionsBuilder matchingBuilder;

  final Widget? childCurrent;

  final String? type;

  final Curve curve;

  final Alignment? alignment;

  final Duration duration;

  final Duration reverseDuration;

  final BuildContext? ctx;

  final bool inheritTheme;

  final bool fullscreenDialog;

  final bool opaque;

  final bool isIos;

  PageTransition({
    Key? key,
    this.child,
    this.type,
    this.childCurrent = null,
    this.ctx,
    this.inheritTheme = false,
    this.curve = Curves.linear,
    this.alignment,
    this.duration = const Duration(milliseconds: 200),
    this.reverseDuration = const Duration(milliseconds: 200),
    this.fullscreenDialog = false,
    this.opaque = false,
    this.isIos = false,
    this.matchingBuilder = const CupertinoPageTransitionsBuilder(),
    RouteSettings? settings,
  })  : assert(inheritTheme ? ctx != null : true,
            "'ctx' cannot be null when 'inheritTheme' is true, set ctx: context"),
        super(
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return inheritTheme
                ? InheritedTheme.captureAll(ctx!, child!)
                : child!;
          },
          settings: settings,
          maintainState: true,
          opaque: opaque,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    switch (type) {
      case "theme":
        return Theme.of(context).pageTransitionsTheme.buildTransitions(
            this, context, animation, secondaryAnimation, child);

      case "leftToRight":
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );

      case 'rightToLeft':
        var slideTransition = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
        if (isIos) {
          return matchingBuilder.buildTransitions(
              this, context, animation, secondaryAnimation, child);
        }
        return slideTransition;

        break;
        break;

      default:
        return FadeTransition(opacity: animation, child: child);
    }
  }
}