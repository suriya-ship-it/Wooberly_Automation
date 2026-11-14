import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/controller/base_controller.dart';

import '../resources/values/app_colors.dart';
import '../resources/values/app_images.dart';
import '../utils/globals.dart' as globals;

class CustomCheckBox extends StatefulWidget {
  final bool initialData;
  final String svgAsset;
  final double size;
  final Color? borderColor;
  final Color? backgroundColor;
  final Function(bool) onChanged;

  CustomCheckBox({
    Key? key,
    required this.initialData,
    this.svgAsset = rideComfortSelectedSvg,
    this.size = 22.0,
    this.borderColor,
    this.backgroundColor,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CustomCheckBoxState createState() => _CustomCheckBoxState();
}

class _CustomCheckBoxState extends State<CustomCheckBox> {
  var rxIsSelected = ReactiveVariable("isSelected", false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.baseController.change(rxVariable: rxIsSelected, value: widget.initialData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: globals.baseController,
      id: rxIsSelected.id,
      builder: (val) {
        return InkWell(
          onTap: () {
            globals.baseController.change(rxVariable: rxIsSelected, value: !rxIsSelected.value);
            widget.onChanged(rxIsSelected.value);
            globals.baseController.change(rxVariable: rxIsSelected, value: rxIsSelected.value);
          },
          child: Container(
            height: widget.size,
            width: widget.size,
            decoration: BoxDecoration(
              color: rxIsSelected.value
                  ? widget.backgroundColor ?? AppColors.PRIMARY_DARK_COLOR
                  : Colors.transparent,
              border: Border.all(color: rxIsSelected.value ? AppColors.PRIMARY_DARK_COLOR :AppColors.CHECK_BOX),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: SvgPicture.asset(
              widget.svgAsset,
              fit: BoxFit.scaleDown,
              colorFilter: ColorFilter.mode(rxIsSelected.value ? AppColors.PRIMARY_COLOR_WHITE : Colors.transparent, BlendMode.srcIn),
            ),
          ),
        );
      }
    );
  }
}