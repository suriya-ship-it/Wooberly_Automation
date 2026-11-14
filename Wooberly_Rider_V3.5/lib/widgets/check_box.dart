import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../resources/values/app_colors.dart';
import '../resources/values/app_images.dart';
import 'package:rxdart/subjects.dart' show BehaviorSubject;

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
  RxBool isSelected = false.obs;

  @override
  void initState() {
    super.initState();
    isSelected.value = widget.initialData;
  }

  @override
  Widget build(BuildContext context) {
    return Obx((){
        return InkWell(
          onTap: () {
              isSelected.value = !isSelected.value;
              widget.onChanged(isSelected.value);
              isSelected(isSelected.value);
          },
          child: Container(
            height: widget.size,
            width: widget.size,
            decoration: BoxDecoration(
              color: isSelected.value
                  ? widget.backgroundColor ?? AppColors.PRIMARY_DARK_COLOR
                  : Colors.transparent,
              border: Border.all(color: isSelected.value ? AppColors.PRIMARY_DARK_COLOR :AppColors.CHECK_BOX),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: SvgPicture.asset(
              widget.svgAsset,
              fit: BoxFit.scaleDown,
              colorFilter: ColorFilter.mode(isSelected.value ? AppColors.PRIMARY_LIGHT_COLOR :Colors.transparent , BlendMode.srcIn),
            ),
          ),
        );
      }
    );
  }
}