import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/resources/values/app_images.dart';

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
            debugPrint('JustTheController: ${_controller}');
            return
              RichText(
                maxLines: 5,
                text: TextSpan(
                  children: [
                    TextSpan(text: widget.title,
                      style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
                        fontWeight: FontWeight.w500,
                        fontSize: AppDimen.text_size_16,
                      ),),
                    WidgetSpan(
                      child: JustTheTooltip(
                          backgroundColor: AppColors.PRIMARY_LIGHT_COLOR,
                          controller:_controller,
                          content: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 20.0,
                                vertical: 10.0),
                            child: Text(
                              widget.tooltipcontent,
                              style: TextStyle(
                                  color:
                                  AppColors.BLACK_TEXT_COLOR,
                                  fontFamily: AppFont.font,
                                  fontSize: AppDimen.text_size_14,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              debugPrint('JustTheController: click ${_controller}');
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
                              padding: const EdgeInsetsDirectional.only(start: 5),
                              child: SvgPicture.asset(
                                vehicleInfoSvg,
                                width: 15.0,
                                height: 15.0,
                                colorFilter: ColorFilter.mode(
                                    AppColors.PRIMARY_ICON_COLOR,
                                    BlendMode.srcIn),
                              ),
                            ),
                          ),

                      ),
                    ),
                  ],
                ),
              );

  }
}