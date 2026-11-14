import 'package:flutter/material.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';

class Timeline extends StatelessWidget {
  const Timeline({
    Key? key,
    required this.children,
    this.indicators,
    this.isLeftAligned = true,
    this.itemGap = 12.0,
    this.gutterSpacing = 10.0,
    this.padding = const EdgeInsets.all(8),
    this.controller,
    this.lineColor = AppColors.LOCATION_LINE_COLOR,
    this.physics,
    this.shrinkWrap = true,
    this.primary = false,
    this.reverse = false,
    this.indicatorSize = 6.0,
    this.lineGap = 2.0,
    this.indicatorStyle = PaintingStyle.fill,
    this.strokeCap = StrokeCap.butt,
    this.strokeWidth = 1.0,
    this.style = PaintingStyle.stroke,
  })  : itemCount = children.length,
        assert(itemGap >= 0),
        assert(lineGap >= 0),
        assert(indicators == null || children.length == indicators.length),
        super(key: key);

  final List<Widget> children;
  final double itemGap;
  final double gutterSpacing;
  final List<Widget>? indicators;
  final bool isLeftAligned;
  final EdgeInsets padding;
  final ScrollController? controller;
  final int itemCount;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool primary;
  final bool reverse;
  final Color lineColor;
  final double lineGap;
  final double indicatorSize;
  final PaintingStyle indicatorStyle;
  final StrokeCap strokeCap;
  final double strokeWidth;
  final PaintingStyle style;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      separatorBuilder: (_, __) => SizedBox(height: itemGap),
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      controller: controller,
      reverse: reverse,
      primary: primary,
      itemBuilder: (context, index) {
        Widget child = children![index];
        List<Widget>? _indicators = indicators;

        Widget? indicator;
        if (_indicators != null) {
          indicator = _indicators[index];
        }

        bool isFirst = index == 0;
        bool isLast = index == itemCount - 1;

        List<Widget> timelineTile = <Widget>[
          CustomPaint(
            foregroundPainter: _TimelinePainter(
              hideDefaultIndicator: indicator != null,
              lineColor: lineColor,
              indicatorColor:  (child as Text).style!.color,
              indicatorSize: indicatorSize,
              indicatorStyle: indicatorStyle,
              isFirst: isFirst,
              isLast: isLast,
              lineGap: lineGap,
              strokeCap: strokeCap,
              strokeWidth: strokeWidth,
              style: style,
              itemGap: itemGap,
            ),
            child: SizedBox(
              height: double.infinity,
              width: indicatorSize,
              child: indicator,
            ),
          ),
          SizedBox(width: gutterSpacing),
          Expanded(child: child),
        ];

        return IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:
                isLeftAligned ? timelineTile : timelineTile.reversed.toList(),
          ),
        );
      },
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    this.hideDefaultIndicator,
    this.indicatorColor,
    this.indicatorStyle,
    this.indicatorSize,
    this.lineGap,
    this.strokeCap,
    this.strokeWidth,
    this.style,
    this.lineColor,
    this.isFirst,
    this.isLast,
    this.itemGap,
  })  : linePaint = Paint()
          ..color = lineColor!
          ..strokeCap = strokeCap!
          ..strokeWidth = strokeWidth!
          ..style = style!,
        circlePaint = Paint()
          ..color = indicatorColor!
          ..style = indicatorStyle!;

  final bool? hideDefaultIndicator;
  final Color? indicatorColor;
  final PaintingStyle? indicatorStyle;
  final double? indicatorSize;
  final double? lineGap;
  final StrokeCap? strokeCap;
  final double? strokeWidth;
  final PaintingStyle? style;
  final Color? lineColor;
  final Paint linePaint;
  final Paint circlePaint;
  final bool? isFirst;
  final bool? isLast;
  final double? itemGap;

  @override
  void paint(Canvas canvas, Size size) {
    final indicatorRadius = indicatorSize! / 2;
    final halfItemGap = itemGap! / 2;
    final indicatorMargin = indicatorRadius + lineGap!;

    final top = size.topLeft(Offset(indicatorRadius, 0.0 - halfItemGap));
    final centerTop = size.centerLeft(
      Offset(indicatorRadius, -indicatorMargin),
    );

    final bottom = size.bottomLeft(Offset(indicatorRadius, 0.0 + halfItemGap));
    final centerBottom = size.centerLeft(
      Offset(indicatorRadius, indicatorMargin),
    );

    if (!isFirst!) canvas.drawLine(top, centerTop, linePaint);
    if (!isLast!) canvas.drawLine(centerBottom, bottom, linePaint);

    if (!hideDefaultIndicator!) {
      final Offset offsetCenter = size.centerLeft(Offset(indicatorRadius, 0));

      if (!isLast!)
        canvas.drawCircle(offsetCenter, indicatorRadius, circlePaint);
      else
        canvas.drawRect(
            size.centerLeft(Offset(0, -indicatorSize! / 2)) &
                Size(indicatorSize!, indicatorSize!),
            circlePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}