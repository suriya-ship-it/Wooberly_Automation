import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/widgets/size_find_widget.dart';

import '../controller/base_controller.dart';
import '../utils/globals.dart' as globals;

class PrimaryButton extends StatefulWidget {
  final String? buttonTitle;
  final String? buttonImage;
  final VoidCallback? callback;
  final bool? isLoad;
  final bool? disableLoadCancel;
  final double? innerPadding;
  final Color? BtnDisableColor;
  final MainAxisSize? mainAxisSize;
  final double? height, titleSize, iconWidth, iconHeight;
  final FontWeight? titleWeight;

  const PrimaryButton(
      {Key? key,
      this.buttonTitle,
      this.buttonImage,
      this.callback,
      this.innerPadding,
      this.height,
      this.mainAxisSize,
      this.isLoad,
      this.BtnDisableColor,
      this.disableLoadCancel,
      this.titleSize,
      this.titleWeight,
      this.iconWidth,
      this.iconHeight})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PrimaryButtonState();
  }
}

class PrimaryButtonState extends State<PrimaryButton> {
  bool _isbuttonClick = false, disableLoadCancel = false;
  Size? _widgetSize;

  @override
  void initState() {
    super.initState();
    if (widget.isLoad != null) _isbuttonClick = widget.isLoad ?? false;

    if (widget.disableLoadCancel != null)
      disableLoadCancel = widget.disableLoadCancel ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BaseController>(
        init: globals.baseController,
        id: globals.rxLoadingController.id,
        builder: (val) {
          if (_isbuttonClick &&
              (globals.rxLoadingController.value == 1 ||
                  (globals.rxLoadingController.value == 2 && disableLoadCancel)) &&
              widget.isLoad == null) _isbuttonClick = false;
          return InkWell(
            onTap: () {
              if (globals.rxLoadingController.value == 1 ||
                  (globals.rxLoadingController.value == 2)) {
                _isbuttonClick = true;
                if (widget.callback != null) widget.callback!();
              }
            },
            child: Container(
                height: widget.height ?? 51,
                padding: EdgeInsetsDirectional.only(
                  start: widget.innerPadding ?? 0,
                  end: widget.innerPadding ?? 0,
                ),
                decoration: BoxDecoration(
                    color: widget.BtnDisableColor ?? AppColors.PRIMARY_COLOR_DARK,
                    borderRadius: BorderRadius.all(Radius.circular(3),
                    ),
                ),
                child: globals.rxLoadingController.value == 0 && _isbuttonClick ||
                        (disableLoadCancel && globals.rxLoadingController.value != 2)
                    ? Container(
                        width: _widgetSize != null ? _widgetSize?.width : 30,
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: 15.0,
                          width: 15.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            backgroundColor: AppColors.PRIMARY_COLOR_DARK,
                            valueColor: new AlwaysStoppedAnimation<Color>(
                                AppColors.CIRCULAR_PROGRESS_BAR_LOADING_COLOR),
                          ),
                        ),
                      )
                    : WidgetSize(
                        onChange: (Size size) {
                          _widgetSize = size;
                        },
                        child: Row(
                          mainAxisSize: widget.mainAxisSize ?? (widget.innerPadding != null
                              ? MainAxisSize.min
                              : MainAxisSize.max),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                widget.buttonTitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: widget.titleWeight != null
                                        ? widget.titleWeight
                                        : FontWeight.w500,
                                    color: AppColors.PRIMARY_COLOR_WHITE,
                                    fontFamily: AppFont.font,
                                    fontSize: widget.titleSize != null
                                        ? widget.titleSize
                                        : AppDimen.text_size_18),
                              ),
                            ),
                            if (widget.buttonImage != null)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(start: 6),
                                child: SvgPicture.asset(
                                  widget.buttonImage!,
                                  colorFilter: ColorFilter.mode(
                                      AppColors.PRIMARY_LIGHT_COLOR,
                                      BlendMode.srcIn),
                                  matchTextDirection: true,
                                  width: widget.iconWidth != null
                                      ? widget.iconWidth
                                      : null,
                                  height: widget.iconHeight != null
                                      ? widget.iconHeight
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ),
            ),
          );
        });
  }
}