import 'package:flutter/widgets.dart';

class AnimatedVisibilityBottomText extends StatefulWidget {
  final bool visible;
  final Widget child;

  const AnimatedVisibilityBottomText({
    Key? key,
    required this.visible,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedVisibilityBottomText> createState() =>
      _AnimatedVisibilityBottomTextState();
}

class _AnimatedVisibilityBottomTextState
    extends State<AnimatedVisibilityBottomText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.visible) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedVisibilityBottomText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (widget.visible) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _heightFactor.value,
            child: FractionalTranslation(
              translation: _slideAnimation.value,
              child: Opacity(
                opacity: _controller.value,
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}