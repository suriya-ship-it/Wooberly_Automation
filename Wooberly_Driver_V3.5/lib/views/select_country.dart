import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/trip_controllers/payout_controller.dart';
import 'package:wooberly_driver/models/country_list_model.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/show_done_view.dart';

class SelectCountry extends StatefulWidget {
  @override
  _SelectCountryState createState() => new _SelectCountryState();
}

class _SelectCountryState extends State<SelectCountry> {
  TextEditingController editingController = TextEditingController();
  final PayoutController _controller = Get.find();
  BuildContext? scoffoldcontext;
  final FocusNode fncountryselect = FocusNode();

  double bottomh = 0;

  _onChanged(String value) {
    List<CountryResults> _newData = _controller
        .allCountries!.getAllCountries!.results!
        .where((results) =>
            results.countryName!.toLowerCase().contains(value.toLowerCase()))
        .toList();

    _controller.setcountryListController(_newData);
  }

  @override
  void initState() {
    _controller.Reset();
    Future.delayed(const Duration(milliseconds: 10), () {
      fncountryselect.unfocus();
      _controller.checkInternet(getCountryList, false);
    });

    super.initState();
  }

  void getCountryList() {
    FocusScope.of(context).requestFocus(fncountryselect);
    if (_controller.allCountries == null) {
      _controller.getCountryList().then((value) {
        if (value.isNotEmpty) {
          _controller.showInSnackBar(value);
        } else {
          _controller.setcountryListController(
              _controller.allCountries!.getAllCountries!.results!);
        }
      });
    } else {
      _controller.setcountryListController(
          _controller.allCountries!.getAllCountries!.results!);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    bottomh = MediaQuery.of(ctx).viewInsets.bottom;
    return PrimaryScaffold(
      disableAppbar: false,
      customAppBarFunction: () {
        _controller.Reset();
        App().setBackNavigation();
      },
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsetsDirectional.only(start: 24, end: 24, top: 20),
                child: GetBuilder(
                  init: PayoutController(),
                    id: _controller.rxCountryListController.id,
                    builder: (val) {
                      return Container(
                          decoration: BoxDecoration(
                            color: AppColors.PRIMARY_COLOR_WHITE,
                            borderRadius:
                                BorderRadius.all(new Radius.circular(3.0)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.COMMON_BG_COLOR,
                                spreadRadius: 2,
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 15.0, end: 8.0),
                                child: SvgPicture.asset(
                                  searchSvg,
                                  colorFilter: ColorFilter.mode(
                                      AppColors.GRAY, BlendMode.srcIn),
                                  width: 13,
                                  height: 13,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: editingController,
                                  focusNode: fncountryselect,
                                  enabled: true,
                                  decoration: InputDecoration(
                                      hintText: search_country.tr,
                                      hintStyle: TextStyle(
                                        color:
                                            AppColors.HIND_TEXT_COLOR,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: AppFont.font,
                                        fontSize: AppDimen.text_size_16,
                                      ),
                                      border: InputBorder.none),
                                  onChanged: _onChanged,
                                  style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontWeight: FontWeight.w500,
                                      fontSize: AppDimen.text_size_16,
                                      fontFamily: AppFont.font),
                                ),
                              )
                            ],
                          ));
                    }),
              ),
              Expanded(
                child: GetBuilder(
                  init: PayoutController(),
                  id: _controller.rxCountryListController.id,
                  builder: (val) {
                    return _controller.rxCountryListController.value.length > 0
                        ? Padding(
                            padding: EdgeInsets.only(bottom: bottomh, top: 14),
                            child: ListView.builder(
                                itemCount: _controller.rxCountryListController.value.length,
                                physics: AlwaysScrollableScrollPhysics(),
                                itemBuilder: (BuildContext ctxt, int Index) {
                                  return Padding(
                                    padding: EdgeInsetsDirectional.symmetric(
                                        horizontal: 24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsetsDirectional.symmetric(
                                              vertical: 5),
                                          child: InkWell(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                      _controller.rxCountryListController.value[Index]
                                                          .countryName!,
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .PRIMARY_COLOR_DARK_TEXT_COLOR,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: AppDimen
                                                              .text_size_16,
                                                          fontFamily:
                                                              AppFont.font)),
                                                ),
                                                Visibility(
                                                  visible: _controller.selectedCountry ==
                                                      _controller.rxCountryListController.value[Index].countryCode,
                                                  child: SvgPicture.asset(
                                                    updatedVerified,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                            AppColors
                                                                .ICON_COLOUR,
                                                            BlendMode.srcIn),
                                                  ),
                                                )
                                              ],
                                            ),
                                            onTap: () {
                                              _controller.Reset();
                                              _controller.countryController
                                                      .text =
                                                  _controller.rxCountryListController.value[Index]
                                                      .countryName;
                                              _controller.selectedCountry =
                                                  _controller.rxCountryListController.value[Index]
                                                      .countryCode;
                                              App().setNavigation(AppRoutes.APP_PAYOUT_ADDRESS);
                                            },
                                          ),
                                        ),
                                        Index != (_controller.rxCountryListController.value.length - 1)
                                            ? Divider(
                                                color: AppColors
                                                    .DIVIDER_COLOR,
                                              )
                                            : SizedBox(
                                                height: MediaQuery.of(context)
                                                            .viewInsets
                                                            .bottom >
                                                        0.0
                                                    ? 80
                                                    : 0,
                                              )
                                      ],
                                    ),
                                  );
                                }),
                          )
                        : editingController.text.toString().length == 0
                            ? const SizedBox.shrink()
                            :  Container(
                                width: Get.width,
                                padding: EdgeInsetsDirectional.only(top: 30),
                                child: Text(
                                  search_valid_country.tr,
                                  style: TextStyle(
                                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                                      fontWeight: FontWeight.w500,
                                      fontSize: AppDimen.text_size_18,
                                      fontFamily: AppFont.font),
                                  textAlign: TextAlign.center,
                                ));
                  },
                ),
              ),
            ],
          ),
          Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              right: 0.0,
              left: 0.0,
              child: MediaQuery.of(context).viewInsets.bottom > 0.0
                  ? InputDoneView()
                  : const SizedBox.shrink()),
        ],
      ),
      onChanged: (map) {
        scoffoldcontext = map["scoffoldcontext"];
      },
    );
  }

}