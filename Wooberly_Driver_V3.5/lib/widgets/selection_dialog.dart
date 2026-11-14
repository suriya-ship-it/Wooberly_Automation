import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/base_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/country_code.dart';
import 'package:wooberly_driver/widgets/primary_scaffold.dart';
import 'package:get/get.dart';
import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';

class SelectionDialog extends StatefulWidget {
  final List<CountryCode> elements;
  final bool? showCountryOnly;
  final double? toppadding;
  final double? height;
  final InputDecoration? searchDecoration;
  final TextStyle? searchStyle;
  final WidgetBuilder? emptySearchBuilder;
  final bool? showFlag;
  final List<CountryCode>? favoriteElements;

  SelectionDialog(this.elements, this.favoriteElements,
      {Key? key,
      this.showCountryOnly,
      this.emptySearchBuilder,
      this.toppadding,
      this.height,
      InputDecoration searchDecoration = const InputDecoration(),
      searchStyle = const TextStyle(),
      this.showFlag})
      : assert(searchDecoration != null, 'searchDecoration must not be null!'),
        this.searchDecoration = searchDecoration.copyWith(
          hintText: Search_country.tr,
          border: InputBorder.none,
          hintStyle: TextStyle(
            fontSize: AppDimen.text_size_16,
            color: AppColors.HIND_TEXT_COLOR,
          ),
        ),
        this.searchStyle = TextStyle(
          color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
          fontSize: AppDimen.text_size_16,
        ),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  List<CountryCode>? filteredElements;

  var rxRefreshController = ReactiveVariable("rxRefreshController", false);
  int incrementcount = 20;
  int? intialcount;
  ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        disableAppbar: true,
        body: ColoredBox(
          color: AppColors.COMMON_BG_COLOR,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                height: 70.0,
                margin: EdgeInsetsDirectional.only(top: widget.toppadding!),
                width: Get.width,
                alignment: Alignment.center,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      margin: const EdgeInsetsDirectional.only(start: 24.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.PRIMARY_COLOR_WHITE),
                      child: SvgPicture.asset(
                        primaryLeftArrow,
                        matchTextDirection: true,
                        height: 25,
                        fit: BoxFit.scaleDown,
                        colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 24),
                child: Text(
                  Search_country.tr,
                  style: TextStyle(
                    color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                    fontWeight: FontWeight.w600,
                    fontSize: AppDimen.text_size_20,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              _showSearchEditView(context),
              const  SizedBox(
                height: 20,
              ),
              Expanded(
                child: _showCountryList(context),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildOption(CountryCode e) {
    return SizedBox(
      width: Get.width,
      child: Column(
        children: [
          const SizedBox(
            height: 7,
          ),
          Row(
            children: <Widget>[
              widget.showFlag!
                  ? SizedBox(
                      width: 20.0,
                      child: Image.asset(
                        e.flagUri!,
                        width: 20.0,
                      ),
                    )
                  : const SizedBox.shrink(),
              !widget.showCountryOnly!
                  ? Container(
                      width: 50,
                      padding: const EdgeInsetsDirectional.only(start: 5.0),
                      child: Text(
                        e.toString(),
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                            fontSize: AppDimen.text_size_16,
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                      ),
                    )
                  : const SizedBox.shrink(),
              Container(
                width: Get.width - 140,
                padding: const EdgeInsetsDirectional.only(start: 20.0),
                child: Text(
                  e.toCountryStringOnly(),
                  style: TextStyle(
                      fontSize: AppDimen.text_size_16,
                      color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                ),
              ),
            ],
          ),
          const  SizedBox(
            height: 7,
          ),
          const  Divider(),
        ],
      ),
    );
  }

  Widget _buildEmptySearchWidget(BuildContext context) {
    if (widget.emptySearchBuilder != null) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(
          bottom: 20.0,
        ),
        child: widget.emptySearchBuilder!(context),
      );
    }

    return Center(
      child: Text(
        No_Country_Found.tr,
        style: TextStyle(
            color: AppColors.HIND_TEXT_COLOR,
            fontFamily: AppFont.font,
            fontWeight: FontWeight.w400,
            fontSize: AppDimen.text_size_16),
      ),
    );
  }

  @override
  void initState() {
    filteredElements = widget.elements;
    intialcount = incrementcount + incrementcount;

    super.initState();
  }

  void _filterElements(String s) {
    intialcount = incrementcount;
    s = s.toUpperCase();
      filteredElements = widget.elements
          .where((e) =>
              e.code!.contains(s) ||
              e.dialCode!.contains(s) ||
              e.name!.toUpperCase().contains(s))
          .toList();
      globals.baseController.change(rxVariable: rxRefreshController, value: true);
  }

  void _selectItem(CountryCode e) {
    Navigator.pop(context, e);
  }

  _showSearchEditView(BuildContext context) {
    return Container(
      width: Get.width,
      decoration: BoxDecoration(
        color: AppColors.PRIMARY_COLOR_WHITE,
        borderRadius: BorderRadius.all(const Radius.circular(3.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.COMMON_BG_COLOR,
            spreadRadius: 2,
            blurRadius: 15,
          ),
        ],
      ),
      margin: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 14.0, end: 6.0),
            child: SvgPicture.asset(
              searchSvg,
              colorFilter: ColorFilter.mode(AppColors.GRAY, BlendMode.srcIn),
              width: 13,
              height: 13,
            ),
          ),
          Expanded(
            child: TextField(
              enableIMEPersonalizedLearning: false,
              style: widget.searchStyle,
              decoration: widget.searchDecoration,
              cursorColor: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
              onChanged: _filterElements,
            ),
          ),
        ],
      ),
    );
  }

  _showCountryList(BuildContext context) {
    Timer.periodic(Duration(milliseconds: 50), (t) {
      if (filteredElements!.length > intialcount!) {
        intialcount = intialcount! + incrementcount;
        if (filteredElements!.length > intialcount!) {
          globals.baseController.change(rxVariable: rxRefreshController, value: true);
        } else {
          int pend = filteredElements!.length - intialcount!;
          intialcount = intialcount! + pend;
          globals.baseController.change(rxVariable: rxRefreshController, value: true);
          t.cancel();
        }
      } else {
        intialcount = filteredElements!.length;
        globals.baseController.change(rxVariable: rxRefreshController, value: true);
        t.cancel();
      }
    });

    return Container(
      height: widget.height,
      color: AppColors.COMMON_BG_COLOR,
      padding: EdgeInsetsDirectional.only(
          start: 30.0,
          end: 30.0,
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GetBuilder(
          init: globals.baseController,
          id: rxRefreshController.id,
          builder: (val) {
            if (!(filteredElements!.length > intialcount!)) {
              intialcount = filteredElements!.length;
            }

            return intialcount! > 0
                ? ListView(children: [
                    for (var i = 0; i < intialcount!; i++)
                      InkWell(
                          key: Key(filteredElements![i].toLongString()),
                          onTap: () {
                            _selectItem(filteredElements![i]);
                            globals.currentShowingPage = AppRoutes.APP_OTP_VERIFY;
                          },
                          child: _buildOption(filteredElements![i]))
                  ])
                : _buildEmptySearchWidget(context);
          }),
    );
  }
}