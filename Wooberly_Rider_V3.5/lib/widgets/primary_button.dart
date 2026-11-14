import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/model_theme.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/size_find_widget.dart';

import '../app/enums/button_state.dart';
import 'single_tap_event.dart';

class PrimaryButton extends StatefulWidget{

  final String? buttonTitle;
  final String? buttonImage;
  final VoidCallback? callback;
  final bool? isLoad;
  final bool? disableLoadCancel;
  final Color? buttonColor;
  final Color? textColor;
  final double? innerPadding;
  final double? height,titleSize,iconWidth,iconHeight;
  final FontWeight? titleWeight;
  final double? maxWidth;

  const PrimaryButton({Key? key,
    this.buttonTitle,
    this.buttonImage,
    this.callback,
    this.innerPadding,
    this.height,
    this.buttonColor,
    this.textColor,
    this.isLoad,
    this.disableLoadCancel,
    this.titleSize,
    this.titleWeight,
    this.iconWidth,
    this.iconHeight,
    this.maxWidth}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PrimaryButtonState();
  }

}

class PrimaryButtonState extends State<PrimaryButton>{

  bool _isbuttonClick = false, disableLoadCancel = false;
  Size? _widgetSize ;
  @override
  void initState() {
    
    super.initState();
    if(widget.isLoad !=null)
      _isbuttonClick = widget.isLoad!;

    if(widget.disableLoadCancel !=null)
      disableLoadCancel =  widget.disableLoadCancel!;

  }


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = globals.buttonState.value;
            if (_isbuttonClick && (state==ButtonState.idle||
                (state==ButtonState.disabled)) &&
                widget.isLoad == null)
              _isbuttonClick = false;

            return SingleTapEvent(
              onTap: () {
                if (state==ButtonState.idle ||
                    (state==ButtonState.disabled)) {
                  _isbuttonClick = true;
                  widget.callback!();
                }
              },
              child: Container(
                  height: widget.height ?? 51,
                  padding:  EdgeInsetsDirectional.only(
                    start: widget.innerPadding ?? 0,
                    end: widget.innerPadding ?? 0,),
                  decoration: BoxDecoration(
                      color: widget.buttonColor ?? AppColors.PRIMARY_DARK_COLOR,
                      borderRadius:const BorderRadius.all(Radius.circular(3))
                  ),
                  child: (state==ButtonState.loading && _isbuttonClick) ||
                      (disableLoadCancel && state!=ButtonState.disabled&&state!=ButtonState.idle) ?
                  Container(
                    width: _widgetSize != null ? _widgetSize!.width : 30,
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 15.0,
                      width: 15.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        backgroundColor: AppColors.PRIMARY_DARK_COLOR,
                        valueColor: new AlwaysStoppedAnimation<Color>(
                            globals.isDarkTheme?AppColors.PRIMARY_LIGHT_COLOR:AppColors.INDICATOR_COLOR),
                      ),
                    ),
                  ) :
                  WidgetSize(
                    onChange: (Size size) {
                      _widgetSize = size;
                    },
                    child: Row(
                      mainAxisSize: widget.innerPadding != null ? MainAxisSize
                          .min : MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: widget.maxWidth ?? double.infinity
                          ),
                          child: Text(
                            widget.buttonTitle!,
                            style: TextStyle(
                              overflow: TextOverflow.ellipsis,
                                fontWeight: widget.titleWeight != null ? widget
                                    .titleWeight : FontWeight.w500,
                                color: widget.textColor ??
                                    AppColors.PRIMARY_LIGHT_COLOR,
                                fontFamily: AppFont.font,
                                fontSize: widget.titleSize != null ? widget
                                    .titleSize : AppDimen.text_size_18
                            ),
                          ),
                        ),
                        if(widget.buttonImage!.isNotEmpty)
                          Consumer<ModelTheme>(
                              builder: (context, ModelTheme themeNotifier, child) {
                              return Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 6, top: 4),
                                child: RotatedBox(
                                  quarterTurns: globals.isRTLLang ? 2 : 0,
                                  child:
                                  SvgPicture.asset(
                                    widget.buttonImage!,
                                    colorFilter: ColorFilter.mode(
                                        widget.textColor ??
                                            AppColors.PRIMARY_LIGHT_COLOR,
                                        BlendMode.srcIn),
                                    width: widget.iconWidth != null ? widget
                                        .iconWidth : null,
                                    height: widget.iconHeight != null ? widget
                                        .iconHeight : null,
                                  ),
                                ),
                              );
                            }
                          ),


                      ],
                    ),
                  )
              ),
            );
    }
    );
  }

}