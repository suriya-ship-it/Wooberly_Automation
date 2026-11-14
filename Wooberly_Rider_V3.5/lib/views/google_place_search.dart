import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/register_controller.dart';
import 'package:app_name/views/flutter_google_places.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../controllers/base_controller.dart';
import '../widgets/primary_scaffold.dart';


class CitySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  CitySearchView();
  }
}

class CitySearchView extends PlacesAutocompleteWidget {

  @override
  _AutoCompleteState createState() => _AutoCompleteState();
}

class _AutoCompleteState extends PlacesAutocompleteState {
  GlobalKey searchScaffoldKey = GlobalKey<ScaffoldState>();
  RegisterController _registerController =Get.find();
  late BuildContext scaffoldContext;

  @override
  void initState() {
    PlacesAutocompleteState.focus = true;
    PlacesAutocompleteWidget.isRegister = true;
    if (PlacesAutocompleteState.queryTextController != null)
      PlacesAutocompleteState.queryTextController!.text =
          _registerController.selectedPlace = _registerController.selectedLocationController.text;

    super.initState();
  }

  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
    return PrimaryScaffold(
      customAppBarFunction: () {
        _goBack(context);
      },
      body: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 25.0),
        child: ListView(
            children: <Widget>[
              const SizedBox(height: 25.0),
              Text(
                'whats_your_location_'.tr,
                style: TextStyle(
                    color: AppColors.BLACK_TEXT_COLOR,
                    fontSize: AppDimen.text_size_22,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 25.0),
              _registerController.showSelected
                  ? InkWell(
                      onTap: () {
                        PlacesAutocompleteState.queryTextController!.text = _registerController.selectedPlace;
                          _registerController.showSelected = false;
                      },
                      child: Container(
                        constraints: BoxConstraints(minHeight: 51),
                        padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
                        alignment: AlignmentDirectional.centerStart,
                        color: AppColors.PRIMARY_LIGHT_COLOR,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 15,
                            ),
                            SvgPicture.asset(
                              updatedlocation,
                              width: 16,
                              height: 16,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                _registerController.selectedPlace,
                                style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppDimen.text_size_16,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 7,
                            ),
                            Visibility(
                              visible: _registerController.selectedPlace.isNotEmpty,
                              child: AnimatedOpacity(
                                duration: Duration(milliseconds: 500),
                                opacity: _registerController.selectedPlace.isNotEmpty
                                    ? 1
                                    : 0,
                                child: InkWell(
                                  highlightColor: AppColors.PRIMARY_LIGHT_COLOR,
                                  focusColor: AppColors.PRIMARY_LIGHT_COLOR,
                                  onTap: () {
                                    PlacesAutocompleteState.queryTextController?.text = "";
                                   _registerController.showSelected = false;
                                  },
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(end: 10.0),
                                    child: SvgPicture.asset(
                                      closeCircleIcon,
                                      width: 20,
                                      height: 20,
                                      colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ColoredBox(
                      color: AppColors.PRIMARY_LIGHT_COLOR,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 15,
                              ),
                              SvgPicture.asset(
                                updatedlocation,
                                width: 16,
                                height: 16,
                              ),
                              Expanded(
                                child: AppBarPlacesAutoCompleteTextField(
                                  avoidUnderline: true,
                                  hintText: 'search_your_location'.tr,
                                ),
                              ),

                              SizedBox(
                                width: 7,
                              ),
                              Visibility(
                                visible: PlacesAutocompleteState.queryTextController!.text.isEmpty
                                    ? false
                                    : true,
                                child: AnimatedOpacity(
                                  duration: Duration(milliseconds: 500),
                                  opacity: PlacesAutocompleteState.queryTextController!.text.isEmpty
                                      ? 0
                                      : 1,
                                  child: InkWell(
                                    highlightColor: AppColors.PRIMARY_LIGHT_COLOR,
                                    focusColor: AppColors.PRIMARY_LIGHT_COLOR,
                                    onTap: () {
                                      PlacesAutocompleteState.queryTextController?.text = "";
                                      _registerController.showSelected = false;
                                    },
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          end: 10.0),
                                      child: SvgPicture.asset(
                                          closeCircleIcon,
                                          width: 20,
                                          height: 20,
                                          colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Obx(() => (globals.placeSearchingController.value) ?
                            _registerController.linearLoader() : const SizedBox.shrink())
                        ],
                      ),
                    ),
              _registerController.showSelected
                  ? const SizedBox.shrink()
                  : Container(
                      height: MediaQuery.of(context).size.height - 230 - (MediaQuery.of(context).viewInsets.bottom),
                      padding: const EdgeInsetsDirectional.only(top: 8.0),
                      child: Obx(() {
                        final data = globals.placeSearchingController.value;
                        return PlacesAutocompleteResult(onTap: (_prediction) {
                          globals.setButtonIdle();
                          displayPrediction(_prediction);
                          _registerController.selectedPlace = _prediction['description'];
                          _registerController.showSelected = true;
                        });
                      }),
                    ),
            ]),
      ),
      onChanged: (map) {
        searchScaffoldKey = map["scaffoldkey"];
        scaffoldContext = map["scaffoldcontext"];
      },
    );
        }
    );
  }

  _goBack(BuildContext context) {
    _registerController.selectedPlace = '';
    PlacesAutocompleteState.queryTextController!.text = "";
    if (_registerController.selectedLocationController.text.isNotEmpty)
      _registerController.showSelected = true;
    _registerController.setBackNavigation();
  }


  @override
  void onResponse(dynamic response) {
    super.onResponse(response);
    if (response != null) {
      _registerController.predictions = response;
    } else {
      _registerController.predictions = [];
    }
  }

  Future<Null> displayPrediction(Map<String,dynamic> p) async {
    if (p != null) {
      _registerController.selectedLocationController.text = p['description'];
      _registerController.showSelected = true;
      globals.placeSearchingController.refresh();
      _registerController.findPlaces(p['place_id']).then((value) {
        final lat = value.latitude;
        final lng = value.longitude;
        ScaffoldMessenger.of(scaffoldContext).removeCurrentSnackBar();
        _registerController.latController = lat;
        _registerController.lngController = lng;
        _registerController.cityController = globals.placeDetails['city'] ?? '';
        _registerController.stateController = globals.placeDetails['state'] ?? '';
        _registerController.zipcodeController = globals.placeDetails['zipcode'] ?? '';
        _registerController.countryController = globals.placeDetails['country'] ?? '';
        globals.placeDetails.clear();
        _registerController.setBackNavigation();
      });
    }
  }

}