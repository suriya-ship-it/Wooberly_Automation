import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/resources/values/app_images.dart';

class TooltipInfoWidget extends StatefulWidget {
  final String title;
  final String tooltipcontent;
  const TooltipInfoWidget({Key? key,required this.title,required this.tooltipcontent,}) : super(key: key);

  @override
  State<TooltipInfoWidget> createState() => _TooltipInfoWidgetState();
}

class _TooltipInfoWidgetState extends State<TooltipInfoWidget> {
  late final JustTheController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JustTheController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return
      RichText(
        maxLines: 5,
        text: TextSpan(
          children: [
            TextSpan(text: widget.title,
              style: TextStyle(
                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                fontWeight: FontWeight.w500,
                fontSize: AppDimen.text_size_16,
              ),),
            WidgetSpan(child: const SizedBox(width: 5,)),
            WidgetSpan(
              child: JustTheTooltip(
                  backgroundColor: AppColors.PRIMARY_COLOR_WHITE,
                  preferredDirection: AxisDirection.down,
                  controller:_controller,
                  content: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0),
                    child: Text(
                      widget.tooltipcontent,
                      style: TextStyle(
                          color:
                          AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                          fontFamily: AppFont.font,
                          fontSize: AppDimen.text_size_14,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _controller.showTooltip();
                        }
                      });

                      Future.delayed(const Duration(seconds: 8), () {
                        if (mounted) {
                          _controller.hideTooltip();
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: SvgPicture.asset(
                        vehicleInfoSvg,
                        width: 13.0,
                        height: 13.0,
                        colorFilter: ColorFilter.mode(
                            AppColors.PRIMARY_COLOR_DARK,
                            BlendMode.srcIn),
                      ),
                    ),
                  ),
              ),
            ),
            WidgetSpan(child: const SizedBox(width: 5,)),
          ],
        ),
      );

  }
}