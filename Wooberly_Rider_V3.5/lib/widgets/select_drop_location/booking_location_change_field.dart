import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/utils/map_utils.dart';
import 'package:app_name/controllers/map_main_controller/map_main_controller.dart';
import 'package:app_name/views/flutter_google_places.dart';
import 'package:app_name/widgets/select_drop_location/booking_location_field.dart';

// ─── Stop Entry Model ──────────────────────────────────────────────────────



// ─── Location Input Widget ─────────────────────────────────────────────────

class BookingLocationChangeField extends StatefulWidget {
  final bool isFromSchedule;
  final MapMainController mapMainController;
  final List<LocationData> locationData;
  final VoidCallback onDisableLocationOTap;

  final ValueChanged<List<LocationData>>? onLocationDataChanged;

  RxBool refreshlocationData = false.obs;

  BookingLocationChangeField({
    Key? key,
    required this.isFromSchedule,
    required this.mapMainController,
    required this.onDisableLocationOTap,
    required this.locationData,
    required this.onLocationDataChanged,
  }) : super(key: key);

  @override
  State<BookingLocationChangeField> createState() => _LocationInputWidgetState();
}

class _LocationInputWidgetState extends State<BookingLocationChangeField> {

  int BottomDestinationAddedIndex = -1;
  Set<LocationData> _newlyAdded = {};


  void _addDestinationAndFocus() {

    var newLoc = LocationData(LatLng(0.0, 0.0), "");
    widget.locationData.add(newLoc);
    _newlyAdded.add(newLoc);
    // Force-add so destination entry always gets created regardless of current count
    widget. locationData.forEach((element){
      debugPrint('locationText: adddeststop ${element.location} --- ${element.latLng} -- ${globals.tripStatus}');
    });
    final destIndex = widget.locationData.length - 1;
    PlacesAutocompleteState.queryTextController?.clear();
    debugPrint("_addDestinationAndFocus: called: ${destIndex}");
    PlacesAutocompleteState.activeStopIndex = destIndex;
  }


  void _addStopInBetweenAndFocus() {
    // Insert before the destination (last element)
    final insertIndex =
    //BottomDestinationAddedIndex !=-1 ? BottomDestinationAddedIndex :
    widget.locationData.length - 1;
  debugPrint("_addStopInBetweenAndFocus called: ${insertIndex} --- ${BottomDestinationAddedIndex}");
    var newLoc = LocationData(LatLng(0.0, 0.0), "");
    widget.locationData.insert(insertIndex, newLoc);
    _newlyAdded.add(newLoc);
    // Insert entry before the last stopEntry (destination)
    PlacesAutocompleteState.queryTextController?.clear();
    PlacesAutocompleteState.activeStopIndex = insertIndex;
  }



  @override
  Widget build(BuildContext context) {
    debugPrint("indexsf:build ${widget.mapMainController.EditDisableLocationsDataIndex}  ---${widget.locationData} --- ${BottomDestinationAddedIndex}--- ${PlacesAutocompleteState.activeStopIndex} --- ${PlacesAutocompleteState.queryTextController?.text}");
    widget.onLocationDataChanged?.call(widget.locationData);
    return Column(
      children: [
        AnimatedDestinationField(
          key: widget.locationData.isNotEmpty ? ObjectKey(widget.locationData[0]) : null,
          hintText: 'enter_pickup'.tr,
          stopIndex: 0,
          animDuration: 0,
          locationData: widget.locationData,
          mapMainController: widget.mapMainController,
          showAddStop: false,
          showClose: false,
          isDisable: false,
          isReached: false,
          isShowSpace: !widget.isFromSchedule,
          onAddStopTap: () {},
          onDisableLocationOTap: () {},
          onRemove: () {},
        ),
        if (widget.isFromSchedule)
        AnimatedDestinationField(
          key: widget.locationData.length > 1 ? ObjectKey(widget.locationData[1]) : null,
          hintText: 'enter_drop'.tr,
          stopIndex: 1,
          animDuration: 0,
          locationData: widget.locationData,
          mapMainController: widget.mapMainController,
          showAddStop: false,
          showClose: false,
          isReached: false,
          isShowSpace: !widget.isFromSchedule,
          isDisable: false,
          onAddStopTap: () {},
          onDisableLocationOTap: () {
            widget.onDisableLocationOTap();
          },
          onRemove: () {},
        ),

        if(!widget.isFromSchedule)
          ...[
            for(int i = 1; i <=widget.locationData.length-1; i++)
              AnimatedDestinationField(
                hintText: i ==widget.locationData.length-1 ? 'enter_drop'.tr : 'enter_stop'.tr,
                stopIndex: i,
                animDuration: _newlyAdded.contains(widget.locationData[i]) ? 300 : 0,
                locationData: widget.locationData,
                mapMainController: widget.mapMainController,
                showAddStop: widget.locationData.length==2 || (i==widget.locationData.length-1 &&  widget.locationData.length < globals.maxStops+2 && widget.locationData[i].location!.isNotEmpty),
                showClose:  widget.locationData.length>2 && i <= widget.locationData.length-1,
                isDisable: i==widget.mapMainController.EditDisableLocationsDataIndex,
                isReached:i<widget.mapMainController.EditDisableLocationsDataIndex && i !=0,
                isShowSpace: true,
                onAddStopTap: () {
                  debugPrint("index: ${i} -- ${widget.locationData.length} --- ${BottomDestinationAddedIndex} --- ${widget.mapMainController.EditDisableLocationsDataIndex}");
                  if(widget.locationData.length-1 == widget.mapMainController.EditDisableLocationsDataIndex){
                    _addDestinationAndFocus();
                  } else {
                    _addStopInBetweenAndFocus();
                  }
                  widget.mapMainController.update(['placeSelectController']);
                },
                onDisableLocationOTap: (){
                  widget.onDisableLocationOTap();
                },
                onRemove: () {
                  if(i ==widget.locationData.length-1){
                    BottomDestinationAddedIndex = -1;
                  }
                  debugPrint("removeindex: ${i} --- ${widget.locationData.length}");
                  if (i < widget.locationData.length) {
                    widget.locationData.removeAt(i);
                  }

                  if(widget.locationData.length == 2){
                    PlacesAutocompleteState.activeStopIndex = 1;
                  }
                  PlacesAutocompleteState.focus = false;
                  widget.locationData.forEach((element){
                    debugPrint('locationText: local 3 ${element.location} --- ${element.latLng} -- ${PlacesAutocompleteState.selectLocationEnum} --- ${PlacesAutocompleteState.activeStopIndex}');
                  });
                  widget.mapMainController.update(['placeSelectController']);
                },
              ),
          ]
      ],
    );
  }
}