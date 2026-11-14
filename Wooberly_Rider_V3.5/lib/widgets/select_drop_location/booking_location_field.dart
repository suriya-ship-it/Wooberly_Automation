import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/utils/map_utils.dart';
import 'package:app_name/controllers/map_main_controller/map_main_controller.dart';
import 'package:app_name/views/flutter_google_places.dart';

class AnimatedDestinationField extends StatefulWidget {
  final int stopIndex;
  final MapMainController mapMainController;
  final List<LocationData> locationData;
  final bool showAddStop;
  final bool showClose;
  final bool isDisable;
  final bool isReached;
  final bool isShowSpace;
  final int animDuration;
  final String hintText;
  final VoidCallback onAddStopTap;
  final VoidCallback onDisableLocationOTap;
  final VoidCallback onRemove;

  const AnimatedDestinationField({
    Key? key,
    required this.stopIndex,
    required this.mapMainController,
    required this.locationData,
    required this.showAddStop,
    required this.isShowSpace,
    required this.showClose,
    required this.isDisable,
    required this.isReached,
    required this.hintText,
    required this.animDuration,
    required this.onAddStopTap,
    required this.onDisableLocationOTap,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<AnimatedDestinationField> createState() =>
      AnimatedDestinationFieldState();
}

class AnimatedDestinationFieldState extends State<AnimatedDestinationField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;

  static const double kFieldHeight = 50;
  static const double kRowGap = 14;     // <-- the visual gap you want between fields
  static const double kDotSize = 5;

  @override
  void initState() {
    super.initState();
    if (widget.stopIndex < widget.locationData.length) {
      debugPrint(
          "locationText: 233 ${widget.locationData[widget.stopIndex].location}");
    } else {
      debugPrint(
          "locationText: 233 stopIndex=${widget.stopIndex} out of bounds (length=${widget.locationData.length})");
    }
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animDuration == 0 ? 300 : widget.animDuration),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _sizeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.animDuration > 0) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRemove() async {
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _fadeAnimation = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _sizeAnimation = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    await _controller.reverse();
    widget.onRemove();
  }


  @override
  Widget build(BuildContext context) {
    final isEditing =
        PlacesAutocompleteState.activeStopIndex == widget.stopIndex &&
        PlacesAutocompleteState.focus;

    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: -1.0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            // top-align so the field sits at the top of the (taller) indicator row,
            // leaving the gap as blank space below the field — exactly where the
            // divider tail runs
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationIndicator(),
              const SizedBox(width: 5,),
              Expanded(
                child: Container(
                  height: kFieldHeight,
                  alignment: AlignmentDirectional.centerStart,
                  decoration: BoxDecoration(
                    color: widget.isDisable || widget.isReached || widget.stopIndex==0
                        ? AppColors.DISABLE_COLOR
                        : AppColors.PRIMARY_LIGHT_COLOR,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: isEditing
                      ? _buildTextField(context)
                      : _buildLocationDisplay(context),
                ),
              ),
            AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: widget.isReached
                ? const SizedBox(width: 55)
                : widget.showAddStop
            ? _buildAddButton()
              : widget.isDisable
          ? _buildInfoIcon()
            : widget.showClose
        ? _buildCloseButton()
        : widget.isShowSpace
    ? const SizedBox(width: 55)
        : const SizedBox(),
    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationIndicator() {
    final isFirst = widget.stopIndex == 0;
    final isLast = widget.stopIndex == widget.locationData.length - 1;

    final dotColor = widget.locationData[widget.stopIndex].location==null ||
        widget.locationData[widget.stopIndex].location!.isEmpty ||
        widget.locationData[widget.stopIndex].locationStatus == 'completed' ||
    widget.mapMainController.EditDisableLocationsDataIndex == widget.stopIndex?
    AppColors.LOCATION_ARRIVED_COLOR :
    AppColors.BLACK_TEXT_COLOR;

    const double kHalfGap = (kFieldHeight - kDotSize) / 2;

    return AnimatedSize(
      duration: Duration(milliseconds: widget.animDuration == 0 ? 300 : widget.animDuration),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: kFieldHeight + (isLast ? 0 : kRowGap),
        width: kDotSize + 2,
        child: Column(
          children: [
            SizedBox(
              height: kHalfGap,
              child: isFirst
                  ? null
                  : Center(
                child: Container(
                  width: 1,
                  height: double.infinity,
                  color: AppColors.RADIO_BUTTON_COLOR,
                ),
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: widget.animDuration == 0 ? 1 : widget.animDuration),
              curve: Curves.easeOut,
              width: kDotSize,
              height: kDotSize,
              decoration: ShapeDecoration(
                color: dotColor,
                shape: isLast
                    ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(1))
                    : const CircleBorder(),
              ),
            ),
            if (!isLast)
              Expanded(
                child: Center(
                  child: Container(
                    width: 1,
                    color: AppColors.RADIO_BUTTON_COLOR,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsetsDirectional.only(start: 10),
            child: AppBarPlacesAutoCompleteTextField(
              avoidUnderline: true,
              hintText: 'enter_stop'.tr,

              onSubmitted: (_) {
                debugPrint('widgetisempt: ${PlacesAutocompleteState.queryTextController!.text.isEmpty}');
                if (PlacesAutocompleteState.queryTextController!.text.isEmpty) {
                  widget.locationData.removeAt(widget.stopIndex);
                  widget.locationData.insert(widget.stopIndex, LocationData(LatLng(0.0, 0.0), ""));
                }
                PlacesAutocompleteState.focus = false;
                widget.mapMainController.update(['placeSelectController']);
              },
            ),
          ),
        ),
        GetBuilder<MapMainController>(
            id: 'isEmptyLocationController',
            builder: (_) {
          final isEmpty =
              PlacesAutocompleteState.queryTextController!.text.isEmpty;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isEmpty ? 0 : 1,
            child: InkWell(
              onTap: () {
                PlacesAutocompleteState.queryTextController!.text = "";
                widget.mapMainController.update(['isEmptyLocationController']);
                if (PlacesAutocompleteState.queryTextController!.text.isEmpty) {
                  widget.locationData.removeAt(widget.stopIndex);
                  widget.locationData.insert(widget.stopIndex, LocationData(LatLng(0.0, 0.0), ""));
                }
                widget.mapMainController.update(['placeSelectController']);
              },
              child: Container(
                height: 20,
                width: 20,
                margin: const EdgeInsetsDirectional.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  closeCircleIcon,
                  colorFilter: ColorFilter.mode(
                    AppColors.PRIMARY_DARK_COLOR,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLocationDisplay(BuildContext context) {
    final locationText = widget.stopIndex < widget.locationData.length
        ? (widget.locationData[widget.stopIndex].location ?? "")
        : "";
    final isEmpty = locationText.isEmpty;

    return InkWell(
      onTap: () {
        if(widget.isDisable || widget.isReached || widget.stopIndex==0) return;
        FocusScope.of(context).unfocus();
        widget.mapMainController.checkInternet(() {}, true);
        PlacesAutocompleteState.queryTextController!.text = locationText;
        PlacesAutocompleteState.activeStopIndex = widget.stopIndex;
        PlacesAutocompleteState.focus = true;
        widget.mapMainController.update(['placeSelectController']);
      },
      child: Container(
        height: 50,
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.only(right: 20.0, left: 20.0, bottom: 2.0),
        child: Text(
          isEmpty ? widget.hintText : locationText,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: TextStyle(
            color: isEmpty
                ? AppColors.PLACEHOLDER_TEXT_COLOR
                : AppColors.BLACK_TEXT_COLOR,
            fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
            fontSize: AppDimen.text_size_14,
          ),
        ),
      ),
    );
  }

  /// Add button — tapping this inserts a new intermediate stop before this field
  Widget _buildAddButton() {
    debugPrint('_buildAddButton called');
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      margin: const EdgeInsetsDirectional.only(start: 11),
      child: InkWell(
        onTap: widget.onAddStopTap,
        child: Container(
          height: 43,
          width: 43,
          padding: const EdgeInsetsDirectional.all(11),
          decoration: BoxDecoration(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            borderRadius: const BorderRadius.all(Radius.circular(30)),
          ),
          child: SvgPicture.asset(
            icAddSvg,
            colorFilter: ColorFilter.mode(
              AppColors.PRIMARY_ICON_COLOR,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  /// Close button — shown when max stops reached; tapping removes this field
  Widget _buildCloseButton() {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      margin: const EdgeInsetsDirectional.only(start: 11),
      child: InkWell(
        onTap: _handleRemove,
        child: Container(
          height: 43,
          width: 43,
          padding: const EdgeInsetsDirectional.all(13),
          decoration: BoxDecoration(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            borderRadius: const BorderRadius.all(Radius.circular(30)),
          ),
          child: SvgPicture.asset(
            closeSvg,
            colorFilter: ColorFilter.mode(
              AppColors.PRIMARY_ICON_COLOR,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoIcon() {
    return InkWell(
      onTap: (){
       widget.onDisableLocationOTap();
      },
      child: Container(
        alignment: AlignmentDirectional.centerEnd,
        margin: const EdgeInsetsDirectional.only(start: 11),
        child: Container(
          height: 43,
          width: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.DISABLE_COLOR,
            borderRadius: const BorderRadius.all(Radius.circular(30)),
          ),
          child: Icon(
            Icons.info_outline,
            color: AppColors.PRIMARY_ICON_COLOR,
            size: 20,
          ),
        ),
      ),
    );
  }
}