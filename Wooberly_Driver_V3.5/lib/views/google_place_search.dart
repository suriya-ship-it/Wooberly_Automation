import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/views/flutter_google_places.dart';

import '../app/model_theme.dart';
import '../controller/auth_controllers/register_controller.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';

import '../widgets/primary_scaffold.dart';



class CitySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CitySearchView();
  }
}

class CitySearchView extends PlacesAutocompleteWidget {
  CitySearchView()
      : super(
    apiKey: globals.MAP_KEY,);

  @override
  _AutoCompleteState createState() => _AutoCompleteState();
}

class _AutoCompleteState extends PlacesAutocompleteState {
  GlobalKey searchScaffoldKey = GlobalKey<ScaffoldState>();
  final RegisterController _controller = Get.find();
  bool firstClick = true;
  late BuildContext scaffoldContext;

  @override
  void initState() {
    PlacesAutocompleteState.focus = true;
    PlacesAutocompleteWidget.isRegister = true;
    if (PlacesAutocompleteState.queryTextController != null)
      PlacesAutocompleteState.queryTextController!.text =
          _controller.selectedPlace = _controller.selectedLocationController.text;

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
            child: GetBuilder(
              init: globals.baseController,
              id: PlacesAutocompleteState.rxPlacesAutocompleteRefreshController.id,
              builder: (val) {
                return ListView(
                    children: <Widget>[
                      const SizedBox(height: 25.0),
                      Text(
                        whats_your_location.tr,
                        style: TextStyle(
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontSize: AppDimen.text_size_22,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 25.0),
                      _controller.showSelected
                          ? InkWell(
                              onTap: () {
                                PlacesAutocompleteState.queryTextController!.text = _controller.selectedPlace;
                                  _controller.showSelected = false;
                                globals.baseController.change(rxVariable: PlacesAutocompleteState.rxPlacesAutocompleteRefreshController, value: true);
                              },
                              child: Container(
                                constraints: BoxConstraints(minHeight: 51),
                                alignment:  AlignmentDirectional.centerStart,
                                color: AppColors.PRIMARY_COLOR_WHITE,
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    SvgPicture.asset(
                                      updatedlocation,
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Text(
                                        _controller.selectedPlace,
                                        style: TextStyle(
                                          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                          fontWeight: FontWeight.w500,
                                          fontSize: AppDimen.text_size_16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 7,
                                    ),
                                    Visibility(
                                      visible: _controller.selectedPlace.isNotEmpty,
                                      child: AnimatedOpacity(
                                        duration: Duration(milliseconds: 500),
                                        opacity: _controller.selectedPlace != null &&
                                                _controller.selectedPlace.isNotEmpty
                                            ? 1
                                            : 0,
                                        child: InkWell(
                                          highlightColor: AppColors.PRIMARY_COLOR_WHITE,
                                          focusColor: AppColors.PRIMARY_COLOR_WHITE,
                                          onTap: () {
                                              PlacesAutocompleteState.queryTextController?.text = "";
                                              _controller.selectedPlace = "";
                                              _controller.showSelected = false;
                                              globals.baseController.change(rxVariable: PlacesAutocompleteState.rxPlacesAutocompleteRefreshController, value: true);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional.only(
                                                end: 10.0),
                                            child: SvgPicture.asset(
                                              circleCloseSvg,
                                              width: 20,
                                              height: 20,
                                              colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.PRIMARY_COLOR_WHITE,
                              child: Row(
                                children: [
                                  const SizedBox(
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
                                      hintText: search_your_location.tr,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 7,
                                  ),
                                  Visibility(
                                    visible: PlacesAutocompleteState
                                            .queryTextController!.text.isEmpty
                                        ? false
                                        : true,
                                    child: AnimatedOpacity(
                                      duration: Duration(milliseconds: 500),
                                      opacity: PlacesAutocompleteState
                                              .queryTextController!.text.isEmpty
                                          ? 0
                                          : 1,
                                      child: InkWell(
                                        highlightColor: AppColors.PRIMARY_COLOR_WHITE,
                                        focusColor: AppColors.PRIMARY_COLOR_WHITE,
                                        onTap: () {
                                          PlacesAutocompleteState.queryTextController?.text = "";
                                          _controller.selectedPlace = "";
                                          _controller.showSelected = false;
                                          globals.baseController.change(rxVariable: PlacesAutocompleteState.rxPlacesAutocompleteRefreshController, value: true);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional.only(
                                              end: 10.0),
                                          child: SvgPicture.asset(
                                            circleCloseSvg,
                                              width: 20,
                                              height: 20,
                                              colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      _controller.showSelected
                          ? const SizedBox.shrink()
                          : Container(
                              height: Get.height -
                                  230 -
                                  (MediaQuery.of(context).viewInsets.bottom),
                              padding: const EdgeInsets.only(top: 8.0),
                              child: PlacesAutocompleteResult(
                                  listfooter: Row(
                                    children: [],
                                    mainAxisAlignment: MainAxisAlignment.center,
                                  ),
                                  onTap: (_prediction) {
                                    PlacesAutocompleteState.queryTextController!.text = "";
                                    globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
                                displayPrediction(_prediction);
                                _controller.selectedPlace = _prediction['description'];
                                _controller.showSelected = true;
                                globals.baseController.change(rxVariable: PlacesAutocompleteState.rxPlacesAutocompleteRefreshController, value: true);
                              }),
                            ),
                    ]);
              }
            ),
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
    _controller.selectedPlace = '';
    PlacesAutocompleteState.queryTextController!.text = "";
    if (_controller.selectedLocationController.text.isNotEmpty)
      _controller.showSelected = true;
    App().setBackNavigation();
  }

  @override
  void onResponseError(String response) {
    super.onResponseError(response);
    _controller.showInSnackBar(response);
  }

  @override
  void onResponse(List<Map<String,dynamic>> response) {
    super.onResponse(response);
    if (response != null) {
      _controller!.predictions = response;
    } else {
      _controller!.predictions = null;
    }
    globals.baseController.change(rxVariable: PlacesAutocompleteState.rxPlacesAutocompleteRefreshController, value: true);
  }

  Future<Null> displayPrediction(Map<String,dynamic> p) async {
    if (p != null) {
      _controller.selectedLocationController.text = p['description'];

      App().findPlaces(p['place_id'],sessionId).then((value) {
        final lat = value.latitude;
        final lng = value.longitude;
        ScaffoldMessenger.of(scaffoldContext!).removeCurrentSnackBar();
          _controller?.showSelected = true;
          _controller?.latController = lat;
          _controller?.lngController = lng;
          App().setBackNavigation();
          _getAddressfromLocation(lat, lng);
      });
    }
  }

  void _getAddressfromLocation(double lat, double lng) async {
    List<Placemark> placemarks =
        await Geocoding().placemarkFromCoordinates(lat, lng);
    _controller.cityController = placemarks[0].locality;
    _controller.stateController = placemarks[0].administrativeArea;
    _controller.zipcodeController = placemarks[0].postalCode;
    _controller.countryController = placemarks[0].isoCountryCode;
  }


}