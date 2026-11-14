import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../resources/values/app_colors.dart';

const Duration _kBottomSheetDuration = Duration(milliseconds: 200);
const double _kMinFlingVelocity = 700.0;
const double _kCloseProgressThreshold = 0.5;

class BottomSheet extends StatefulWidget {
  const BottomSheet({
    Key? key,
    this.animationController,
    this.enableDrag = true,
    this.elevation = 0.0,
    required this.onClosing,
    required this.builder,
  })  : assert(enableDrag != null),
        assert(onClosing != null),
        assert(builder != null),
        assert(elevation != null && elevation >= 0.0),
        super(key: key);

  final AnimationController? animationController;

  final VoidCallback onClosing;

  final WidgetBuilder builder;

  final bool enableDrag;

  final double elevation;

  @override
  _BottomSheetState createState() => _BottomSheetState();

  static AnimationController createAnimationController(TickerProvider vsync) {
    return AnimationController(
      duration: _kBottomSheetDuration,
      debugLabel: 'BottomSheet',
      vsync: vsync,
    );
  }
}

class _BottomSheetState extends State<BottomSheet> {
  final GlobalKey _childKey = GlobalKey(debugLabel: 'BottomSheet child');

  double get _childHeight {
    final RenderBox renderBox =
        _childKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }

  bool get _dismissUnderway =>
      widget.animationController?.status == AnimationStatus.reverse;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dismissUnderway) return;
    widget.animationController!.value -= details.primaryDelta! /
        (_childHeight ?? num.parse(details.primaryDelta.toString()));
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dismissUnderway) return;
    if (details.velocity.pixelsPerSecond.dy > _kMinFlingVelocity) {
      final double flingVelocity =
          -details.velocity.pixelsPerSecond.dy / _childHeight;
      if (widget.animationController!.value > 0.0)
        widget.animationController?.fling(velocity: flingVelocity);
      if (flingVelocity < 0.0) widget.onClosing();
    } else if (widget.animationController!.value < _kCloseProgressThreshold) {
      if (widget.animationController!.value > 0.0)
        widget.animationController?.fling(velocity: -1.0);
      widget.onClosing();
    } else {
      widget.animationController?.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget bottomSheet = Material(
      key: _childKey,
      elevation: widget.elevation,
      child: widget.builder(context),
    );
    return !widget.enableDrag
        ? bottomSheet
        : GestureDetector(
            onVerticalDragUpdate: _handleDragUpdate,
            onVerticalDragEnd: _handleDragEnd,
            child: bottomSheet);
  }
}

class _ModalBottomSheetLayout extends SingleChildLayoutDelegate {
  _ModalBottomSheetLayout(this.progress);

  final double progress;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: constraints.maxHeight,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height * progress);
  }

  @override
  bool shouldRelayout(_ModalBottomSheetLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _ModalBottomSheet<T> extends StatefulWidget {
  const _ModalBottomSheet({Key? key, this.route}) : super(key: key);

  final _ModalBottomSheetRoute<T>? route;

  @override
  _ModalBottomSheetState<T> createState() => _ModalBottomSheetState<T>();
}

class _ModalBottomSheetState<T> extends State<_ModalBottomSheet<T>> {
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    String routeLabel = '';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        routeLabel = '';
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        routeLabel = localizations.dialogLabel;
        break;
      case TargetPlatform.linux:
        break;
      case TargetPlatform.macOS:
        break;
      case TargetPlatform.windows:
        break;
    }

    return GestureDetector(
      excludeFromSemantics: true,
      onTap: () => Get.back(),
      child: AnimatedBuilder(
        animation: widget.route!.animation!,
        builder: (BuildContext? context, Widget? child) {
          final double animationValue = mediaQuery.accessibleNavigation
              ? 1.0
              : widget.route!.animation!.value;
          return Semantics(
            scopesRoute: true,
            namesRoute: true,
            label: routeLabel,
            explicitChildNodes: true,
            child: ClipRect(
              child: CustomSingleChildLayout(
                delegate: _ModalBottomSheetLayout(animationValue),
                child: BottomSheet(
                  animationController: widget.route?._animationController,
                  onClosing: () => Get.back(),
                  builder: widget.route!.builder!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModalBottomSheetRoute<T> extends PopupRoute<T> {
  _ModalBottomSheetRoute({
    this.builder,
    this.theme,
    this.barrierLabel,
    RouteSettings? settings,
  }) : super(settings: settings);

  final WidgetBuilder? builder;
  final ThemeData? theme;

  @override
  Duration get transitionDuration => _kBottomSheetDuration;

  @override
  bool get barrierDismissible => true;

  @override
  final String? barrierLabel;

  @override
  Color get barrierColor => AppColors.PRIMARY_COLOR_DARK;

  AnimationController? _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController =
        BottomSheet.createAnimationController(navigator!.overlay!);
    return _animationController!;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: _ModalBottomSheet<T>(route: this),
    );
    if (theme != null) bottomSheet = Theme(data: theme!, child: bottomSheet);
    return bottomSheet;
  }
}

Future<T?> showBottomSheetCustom<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  assert(context != null);
  assert(builder != null);
  return Get.bottomSheet<T>(
    SafeArea(bottom: Platform.isAndroid, child: builder(Get.context!)),
    isScrollControlled: true, // Allows full-screen height if needed
    barrierColor: Colors.black54, // Customize overlay background
  );
}

PersistentBottomSheetController showBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  assert(context != null);
  assert(builder != null);
  return Scaffold.of(context).showBottomSheet(builder);
}