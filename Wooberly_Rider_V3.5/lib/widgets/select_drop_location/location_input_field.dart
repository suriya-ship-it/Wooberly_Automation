import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/utils/map_utils.dart';
import 'package:app_name/controllers/map_main_controller/map_main_controller.dart';
import 'package:app_name/views/flutter_google_places.dart';
import 'package:app_name/resources/values/app_images.dart';

// ─── Stop Entry Model ──────────────────────────────────────────────────────

class StopEntry {
  final int id;
  final bool animate;
  StopEntry({required this.id, this.animate = true});
}

// ─── Stop Controller ───────────────────────────────────────────────────────

class StopController extends GetxController {

  final RxList<StopEntry> stopEntries = <StopEntry>[].obs;
  int _idCounter = 0;

  bool get canAddMore => stopEntries.length < globals.maxStops;
  bool get isMaxReached => stopEntries.length >= globals.maxStops;

  void addStop({bool animate = true}) {
    debugPrint("bookingstopadded");
    if (canAddMore) {
      stopEntries.add(StopEntry(id: _idCounter++, animate: animate));
    }
  }

  void removeStop(int id) {
    stopEntries.removeWhere((e) => e.id == id);
  }

  void clearStops() {
    stopEntries.clear();
    _idCounter = 0; // reset counter too, if you want fresh ids next time
  }
}

// ─── Location Input Widget ─────────────────────────────────────────────────

class LocationInputWidget extends StatefulWidget {
  final bool isFromSchedule;
  final MapMainController mapMainController;
  final List<LocationData> locationData;

  LocationInputWidget({
    Key? key,
    required this.isFromSchedule,
    required this.mapMainController,
    required this.locationData,
  }) : super(key: key);

  @override
  State<LocationInputWidget> createState() => _LocationInputWidgetState();
}

class _LocationInputWidgetState extends State<LocationInputWidget> {
  final StopController stopController = Get.put(StopController());

  @override
  void initState() {
    for (var element in  widget.locationData) {
      debugPrint("locationinput bottomButton element: ${element.location} --- ${element.latLng} --- ${stopController.stopEntries.value}");
    }

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncStopsFromLocationData();
    });
  }

  /// Synchronise the reactive StopController with what's already in locationData.
  /// locationData layout: [pickup, stop1?, stop2?, ..., drop]
  /// So stops count = locationData.length - 2 (min 0).
  void _syncStopsFromLocationData() {
    final existingStopCount =
    (widget.locationData.length - 2).clamp(0, globals.maxStops);
    final currentStopCount = stopController.stopEntries.length;

    if (existingStopCount > currentStopCount) {
      for (int i = currentStopCount; i < existingStopCount; i++) {
        stopController.addStop(animate: false);
      }
    } else if (existingStopCount < currentStopCount) {
      // Remove extra entries from the tail
      while (stopController.stopEntries.length > existingStopCount) {
        final last = stopController.stopEntries.last;
        stopController.removeStop(last.id);
      }
    }
  }

  int _addStopAndFocus() {
    debugPrint(" widget.locationDatalength: ${ widget.locationData.length}");
    final newStopIndex = widget.locationData.length - 1;
    widget.locationData.insert(
      newStopIndex,
      LocationData(LatLng(0.0, 0.0), ""),
    );
    stopController.addStop(animate: true);
    PlacesAutocompleteState.queryTextController?.clear();
    PlacesAutocompleteState.activeStopIndex = newStopIndex;

    return newStopIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pickup
        LocationInputField(
          locationIndex: 0,
          hintText: 'enter_pickup'.tr,
          isFromSchedule: widget.isFromSchedule,
          locationData: widget.locationData,
          mapMainController: widget.mapMainController,
          showAddStop: false,
        ),

        // Dynamic stops
        if (!widget.isFromSchedule && widget.locationData.length>2)
          Obx(() {
            final entries = stopController.stopEntries;
            debugPrint('stopentries: ${entries}');
            return Column(
              children: List.generate(entries.length, (index) {
                final entry = entries[index];
                return _AnimatedStopField(
                  key: ValueKey(entry.id),
                  stopId: entry.id,
                  stopIndex: index + 1,
                  animateOnInit: entry.animate,
                  locationData: widget.locationData,
                  mapMainController: widget.mapMainController,
                  onRemove: () {
                    if (index + 1 < widget.locationData.length - 1) {
                      widget.locationData.removeAt(index + 1);
                    }

                    if( widget.locationData.first.location == null || (widget.locationData.first.location?.isEmpty ?? false))
                      PlacesAutocompleteState.activeStopIndex = 0;

                    else if( widget.locationData.last.location == null || (widget.locationData.last.location?.isEmpty ?? false))
                      PlacesAutocompleteState.activeStopIndex = widget.locationData.length-1;
                    else {
                      widget.locationData.asMap().forEach((index,element){
                        if(element.location ==null || (element.location?.isEmpty ?? false)){
                          PlacesAutocompleteState.activeStopIndex = index;
                        }
                        debugPrint('remove stop ${element.location} --- ${element.latLng} -- ${globals.tripStatus}');
                      });
                    }

                    debugPrint("bottomButton  remove stop locationDta: ${widget.locationData}");
                    stopController.removeStop(entry.id);
                    widget.mapMainController.update(['placeSelectController']);
                  },
                );
              }),
            );
          }),

        // Drop — hide add button when max reached
        (!widget.isFromSchedule)
            ? Obx(() => LocationInputField(
          locationIndex: widget.locationData.length-1,
          hintText: 'enter_drop'.tr,
          isFromSchedule: widget.isFromSchedule,
          locationData: widget.locationData,
          mapMainController: widget.mapMainController,
          showAddStop: !widget.isFromSchedule &&
              (stopController.canAddMore ||  widget.locationData.length==2), // ✅ Hide when max reached
          onAddStopTap: () {
            _addStopAndFocus();
            debugPrint(
                "bottomButton locationDta: ${widget.locationData}");
            widget.mapMainController.update(['placeSelectController']);
          },
        ))
            : LocationInputField(
          locationIndex: widget.locationData.length-1,
          hintText: 'enter_drop'.tr,
          isFromSchedule: widget.isFromSchedule,
          locationData: widget.locationData,
          mapMainController: widget.mapMainController,
          showAddStop: false, // ✅ Hide when max reached
        ),
      ],
    );
  }
}

// ─── Animated Stop Field ───────────────────────────────────────────────────

class _AnimatedStopField extends StatefulWidget {
  final int stopId;
  final int stopIndex;
  final MapMainController mapMainController;
  final VoidCallback onRemove;
  final List<LocationData> locationData;
  final bool animateOnInit;

  const _AnimatedStopField({
    Key? key,
    required this.stopId,
    required this.stopIndex,
    required this.mapMainController,
    required this.onRemove,
    required this.locationData,
    this.animateOnInit = true,
  }) : super(key: key);

  @override
  State<_AnimatedStopField> createState() => _AnimatedStopFieldState();
}

class _AnimatedStopFieldState extends State<_AnimatedStopField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // slide in from bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _sizeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.animateOnInit) {
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
      end: const Offset(0, 1), // slide out to top
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
    debugPrint("widget.stoplocationData: ${widget.locationData} --- ${widget.stopIndex}");
    final isEditing =
        PlacesAutocompleteState.activeStopIndex == widget.stopIndex &&
        PlacesAutocompleteState.focus;

    const double kFieldHeight = 50;
    const double kRowGap = 15;

    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: -1,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LocationDot(
                color:widget.locationData[widget.stopIndex].location!.isNotEmpty ? AppColors.B3_BLACK_COLOR :  AppColors.LOCATION_ARRIVED_COLOR,
                isRect: false,
                showTop: true,
                showBottom: true,
                rowHeight: kFieldHeight + kRowGap,
                fieldHeight: kFieldHeight,
                sizeFactor: _sizeAnimation,
                fadeFactor: _fadeAnimation,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 50,
                  alignment: AlignmentDirectional.centerStart,
                  decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: isEditing
                      ? _buildTextField(context)
                      : _buildLocationDisplay(context),
                ),
              ),
              Container(
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
              )
            ],
          ),
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
            ),
          ),
        ),
        GetBuilder<MapMainController>(builder: (_) {
          final isEmpty =
              PlacesAutocompleteState.queryTextController!.text.isEmpty;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isEmpty ? 0 : 1,
            child: InkWell(
              onTap: () {
                PlacesAutocompleteState.queryTextController!.text = "";
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
    final locationText = widget.locationData[widget.stopIndex].location ?? "";
    final isEmpty = locationText.isEmpty;

    return InkWell(
      onTap: () {
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
          isEmpty ? 'enter_stop'.tr : locationText,
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
}

// ─── Location Input Field ──────────────────────────────────────────────────

class LocationInputField extends StatelessWidget {
  final String hintText;
  final int locationIndex;
  final bool isFromSchedule;
  final MapMainController mapMainController;
  final bool showAddStop;
  final VoidCallback? onAddStopTap;
  final List<LocationData> locationData;

  const LocationInputField({
    Key? key,
    required this.hintText,
    required this.locationIndex,
    required this.isFromSchedule,
    required this.locationData,
    required this.mapMainController,
    this.showAddStop = false,
    this.onAddStopTap,
  }) : super(key: key);

  static const double kFieldHeight = 50;
  static const double kRowGap = 15; // matches Padding(vertical: 8) on both sides

  @override
  Widget build(BuildContext context) {
    final isPickup = locationIndex==0;
    debugPrint("locationinputfield: ${locationIndex} -- ${locationData.length} ");
    final locationText = locationIndex>=0 && locationData.length>0   ?locationData[locationIndex].location : '';
    int index = isPickup ? 0 : locationData.length-1;
 //   debugPrint("locationData[index].location: ${locationData[index].location} -- ${PlacesAutocompleteState.activeStopIndex}");
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LocationDot(
          color: locationText !=null && locationText.isNotEmpty ? AppColors.BLACK :  AppColors.LOCATION_ARRIVED_COLOR,
          isRect: !isPickup,           // pickup = circle, drop = rect
          showTop: !isPickup,           // pickup has nothing above it
          showBottom: isPickup,         // pickup connects down; drop connects to nothing further
          rowHeight: isPickup ? kFieldHeight + kRowGap : kFieldHeight,
          fieldHeight: kFieldHeight,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 50,
            alignment: AlignmentDirectional.centerStart,
            decoration: BoxDecoration(
              color: AppColors.PRIMARY_LIGHT_COLOR,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: locationIndex == PlacesAutocompleteState.activeStopIndex && PlacesAutocompleteState.focus
                ? _buildTextField(context)
                : _buildLocationDisplay(context),
          ),
        ),
        if (!isFromSchedule)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _buildAddStopButton(showAddStop),
          ),
      ],
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
              hintText: hintText,
            ),
          ),
        ),
        GetBuilder<MapMainController>(builder: (_) {
          final isEmpty =
              PlacesAutocompleteState.queryTextController!.text.isEmpty;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isEmpty ? 0 : 1,
            child: InkWell(
              onTap: () {
                checkInternet();
                PlacesAutocompleteState.queryTextController!.text = "";
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

    String locationText = locationIndex>=0 && locationData.length>0   ?(locationData[locationIndex].location ?? '') : '';
    debugPrint("locationText123: ${locationText} --- ${PlacesAutocompleteState.activeStopIndex}");
    final isEmpty = locationText.isEmpty;

    return InkWell(
      onTap: () {
        if(  locationData.length ==2 && locationIndex == PlacesAutocompleteState.activeStopIndex && (globals.tripStatus == "approved" || globals.tripStatus == "locationReached"))
          return;
        FocusScope.of(context).unfocus();
        checkInternet();
        PlacesAutocompleteState.queryTextController!.text = isEmpty ? "" : locationText;
        PlacesAutocompleteState.activeStopIndex = locationIndex;
        PlacesAutocompleteState.focus = true;
        mapMainController.update(['placeSelectController']);
      },
      child: Container(
        height: 50,
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.only(right: 20.0, left: 20.0, bottom: 2.0),
        child: Text(
          isEmpty ? hintText : locationText,
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

  Widget _buildAddStopButton(bool showAddStop) {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      margin: const EdgeInsetsDirectional.only(start: 11),
      child: InkWell(
        onTap: showAddStop ? onAddStopTap : () {},
        child: Container(
          height: 43,
          width: 43,
          padding: const EdgeInsetsDirectional.all(11),
          decoration: showAddStop
              ? BoxDecoration(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            borderRadius: const BorderRadius.all(Radius.circular(30)),
          )
              : null,
          child: showAddStop
              ? SvgPicture.asset(
            icAddSvg,
            colorFilter: ColorFilter.mode(
              AppColors.PRIMARY_ICON_COLOR,
              BlendMode.srcIn,
            ),
          )
              : null,
        ),
      ),
    );
  }

  void checkInternet() {
    mapMainController.checkInternet(() {}, true);
  }
}

class _LocationDot extends StatelessWidget {
  final Color color;
  final bool isRect;          // true for the drop/last field
  final bool showTop;         // draw connector above the dot
  final bool showBottom;      // draw connector below the dot
  final double rowHeight;     // total height of this indicator slot
  final double fieldHeight;   // height of the field box beside it (for centering)
  final double dotSize;
  final Animation<double>? sizeFactor; // only for animated stop fields
  final Animation<double>? fadeFactor;

  const _LocationDot({
    required this.color,
    required this.isRect,
    required this.showTop,
    required this.showBottom,
    required this.rowHeight,
    required this.fieldHeight,
    this.dotSize = 5,
    this.sizeFactor,
    this.fadeFactor,
  });

  Widget _line() => Center(
    child: Container(width: 1, color: AppColors.RADIO_BUTTON_COLOR),
  );

  Widget _animatedLine() {
    if (sizeFactor == null || fadeFactor == null) return _line();
    return SizeTransition(
      sizeFactor: sizeFactor!,
      axisAlignment: -1.0,
      child: FadeTransition(opacity: fadeFactor!, child: _line()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final halfGap = (fieldHeight - dotSize) / 2;
    return SizedBox(
      height: rowHeight,
      width: dotSize + 2,
      child: Column(
        children: [
          SizedBox(
            height: halfGap,
            child: showTop ? _line() : null,
          ),
          Container(
            width: dotSize,
            height: dotSize,
            decoration: ShapeDecoration(
              color: color,
              shape: isRect
                  ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(1))
                  : const CircleBorder(),
            ),
          ),
          if (showBottom) Expanded(child: _animatedLine()),
        ],
      ),
    );
  }
}