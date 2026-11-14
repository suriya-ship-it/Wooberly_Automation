import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart';

import '../resources/values/app_colors.dart';
import '../resources/values/app_images.dart';

class ConfirmationSlider extends StatefulWidget {
  final double height;
  final double width;
  final String text;
  final VoidCallback onConfirmation;

  const ConfirmationSlider({
    super.key,
    this.height = 80,
    this.width = 350,
    this.text = "SWIPE TO START RIDE",
    required this.onConfirmation,
  });

  @override
  State<ConfirmationSlider> createState() => _ConfirmationSliderState();
}

class _ConfirmationSliderState extends State<ConfirmationSlider>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _stripeController;
  late AnimationController _slideController;
  late AnimationController _bounceController;

  late Animation<double> _glowAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _bounceAnimation;

  final ValueNotifier<double> _positionNotifier = ValueNotifier(0);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _stripeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 10.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 10.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 30,
      ),
    ]).animate(_bounceController);

    _slideAnimation = const AlwaysStoppedAnimation(0);

    _slideController.addListener(() {
      _positionNotifier.value = _slideAnimation.value;
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _stripeController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    _positionNotifier.dispose();
    super.dispose();
  }

  void _updatePosition(DragUpdateDetails details) {
    if (!_isDragging) {
      _isDragging = true;
      _bounceController.stop();
    }

    final maxPosition = widget.width - widget.height;

    final newPosition =
    (_positionNotifier.value + details.delta.dx).clamp(
      0.0,
      maxPosition,
    );

    _positionNotifier.value = newPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    final maxPosition = widget.width - widget.height;

    if (_positionNotifier.value >= maxPosition * 0.9) {
      _animateTo(
        maxPosition,
        onCompleted: widget.onConfirmation,
      );
    } else {
      _animateTo(0);
    }
  }

  void _animateTo(
      double endPosition, {
        VoidCallback? onCompleted,
      }) {
    if (!mounted) return;

    _slideAnimation = Tween<double>(
      begin: _positionNotifier.value,
      end: endPosition,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      ),
    );

    _slideController.forward(from: 0).then((_) {
      if (!mounted) return;

      if (endPosition != 0) {
        Future.delayed(
          const Duration(milliseconds: 400),
          () {
            if (mounted) _animateTo(0);
          },
        );

        onCompleted?.call();
      } else {
        _isDragging = false;
        _bounceController.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _positionNotifier,
      builder: (context, position, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnimatedBuilder(
                  animation: _stripeController,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: AnimatedStripePainter(
                        _stripeController.value * 40,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
              ),

              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _glowController,
                    _stripeController,
                  ]),
                  builder: (_, __) {
                    final thumbWidth = widget.height;

                    return SizedBox(
                      width: widget.width,
                      child: ClipPath(
                        clipper: TextRevealClipper(
                          cutPosition: position + thumbWidth,
                        ),
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors:  [
                               AppColors.BUTTON_SLIDER_COLOR,
                                Colors.white,
                                AppColors.BUTTON_SLIDER_COLOR,
                              ],
                              stops: [
                                (_stripeController.value - 0.15)
                                    .clamp(0.0, 1.0),
                                _stripeController.value,
                                (_stripeController.value + 0.15)
                                    .clamp(0.0, 1.0),
                              ],
                            ).createShader(bounds);
                          },
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: Text(
                              widget.text.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppDimen.text_size_18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5,
                                shadows: [
                                  Shadow(
                                    color:AppColors.BUTTON_SLIDER_INNER_COLOR.withValues(
                                      alpha: _glowAnimation.value * .8,
                                    ),
                                    blurRadius: 15,
                                  ),
                                  Shadow(
                                    color: Colors.white.withValues(
                                      alpha: _glowAnimation.value * .3,
                                    ),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              AnimatedBuilder(
                animation: _bounceController,
                builder: (context, _) {
                  final double currentLeft = position == 0 && !_isDragging
                      ? _bounceAnimation.value
                      : position;
                  return Positioned(
                    left: currentLeft,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: 6, end: 6, top: 6),
                      child: GestureDetector(
                        onHorizontalDragUpdate: _updatePosition,
                        onHorizontalDragEnd: _onPanEnd,
                        child: AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (_, __) {
                            return Container(
                              height: widget.height - 12,
                              width: widget.height - 12,
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.BUTTON_SLIDER_INNER_COLOR,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.black.withValues( alpha:0.08),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:  AppColors.BUTTON_SLIDER_INNER_COLOR.withValues(
                                     alpha:  _glowAnimation.value * 0.7,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 1.5,
                                  ),
                                  BoxShadow(
                                    color:  AppColors.BUTTON_SLIDER_INNER_COLOR.withValues(
                                      alpha:_glowAnimation.value * 0.35,
                                    ),
                                    blurRadius: 22,
                                    spreadRadius: 3.5,
                                  ),
                                ],
                              ),
                              child: RotatedBox(
                                quarterTurns: isRtlLang ? 2 : 0,
                                child: SvgPicture.asset(
                                  arrowRightSvg,
                                  matchTextDirection: true,
                                  height: 5,
                                  colorFilter: ColorFilter.mode(
                                  Colors.black, BlendMode.srcIn
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedStripePainter extends CustomPainter {
  final double offset;

  AnimatedStripePainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = AppColors.STRIPE_PAINTER_COLOR;

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
      bgPaint,
    );

    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 10;

    const stripeSpacing = 22.0;

    for (
    double i = -size.height * 2 + offset;
    i < size.width + size.height;
    i += stripeSpacing
    ) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant AnimatedStripePainter oldDelegate,
      ) {
    return oldDelegate.offset != offset;
  }
}

class TextRevealClipper extends CustomClipper<Path> {
  final double cutPosition;

  TextRevealClipper({
    required this.cutPosition,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    path.addRect(
      Rect.fromLTWH(
        cutPosition.clamp(0, size.width),
        0,
        (size.width - cutPosition).clamp(0, size.width),
        size.height,
      ),
    );

    return path;
  }

  @override
  bool shouldReclip(TextRevealClipper oldClipper) {
    return oldClipper.cutPosition != cutPosition;
  }
}