import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/widgets/size_find_widget.dart';

import '../models/select_location_model.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../utils/globals.dart' as globals;

class PlacesAutocompleteWidget extends StatefulWidget {
  static String? hint = "Search Location";
  static bool isRegister = false;
  bool? isFromSchedule = false;

  PlacesAutocompleteWidget({
    this.isFromSchedule,
    Key? key,
  }) : super(key: key);

  @override
  State<PlacesAutocompleteWidget> createState() {
    return PlacesAutocompleteState();
  }
}



class PlacesAutocompleteResult extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onTap;
  final Widget? listFooter;
  final bool? startEndPadding;

  PlacesAutocompleteResult({this.onTap, this.listFooter, this.startEndPadding});

  @override
  _PlacesAutocompleteResult createState() => _PlacesAutocompleteResult();
}

class _PlacesAutocompleteResult extends State<PlacesAutocompleteResult> {
  @override
  Widget build(BuildContext context) {
    if (PlacesAutocompleteState.queryTextController!.text.isEmpty ||
        globals.locationList == null ||
        (globals.locationList.isEmpty)) {
      return const SizedBox.shrink();
    }
    return PredictionsListView(
      listFooter: widget.listFooter ?? const SizedBox.shrink(),
      predictions: globals.locationList,
      onTap: widget.onTap!,
    );
  }
}

class AppBarPlacesAutoCompleteTextField extends StatefulWidget {
  bool avoidUnderline;
  String hintText;

  final ValueChanged<String>? onSubmitted;

  AppBarPlacesAutoCompleteTextField(
      {this.avoidUnderline = false, this.hintText = "",  this.onSubmitted});

  @override
  _AppBarPlacesAutoCompleteTextFieldState createState() => _AppBarPlacesAutoCompleteTextFieldState();
}

class _AppBarPlacesAutoCompleteTextFieldState extends State<AppBarPlacesAutoCompleteTextField> {
  BaseController baseController = Get.find();

  @override
  void initState() {
    PlacesAutocompleteWidget.hint = widget.hintText;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment:  AlignmentDirectional.topStart,
        margin: !widget.avoidUnderline
            ? EdgeInsetsDirectional.only(end: 20.0, start: 20.0, bottom: 20.0)
            : EdgeInsetsDirectional.only(start: 10.0, end: 0.0, bottom: 2.0),
        child: TextField(
          enableIMEPersonalizedLearning: false,
          controller: PlacesAutocompleteState.queryTextController,
          autofocus: PlacesAutocompleteState.focus,
          textInputAction: TextInputAction.search,
          cursorColor: AppColors.BLACK_TEXT_COLOR,
          onSubmitted: (value) {
            if (PlacesAutocompleteState.queryTextController!.text.isEmpty) {
              widget.onSubmitted?.call(value);
            }
          },

          style: TextStyle(
              color: AppColors.BLACK_TEXT_COLOR,
              fontWeight: FontWeight.w500,
              fontSize: PlacesAutocompleteWidget.isRegister ? AppDimen.text_size_16 : AppDimen.text_size_14,
              fontFamily: AppFont.font),
          decoration: InputDecoration(
            hintText: PlacesAutocompleteWidget.hint,
            hintStyle: TextStyle(
              color: AppColors.PLACEHOLDER_TEXT_COLOR,
              fontWeight: FontWeight.w400,
              fontSize: PlacesAutocompleteWidget.isRegister ? AppDimen.text_size_16 : AppDimen.text_size_14,
            ),
            border: !widget.avoidUnderline
                ? new UnderlineInputBorder(
                    borderSide: new BorderSide(
                      color: AppColors.PLACEHOLDER_TEXT_COLOR,
                    ),
                  )
                : InputBorder.none,
          ),
        ));
  }
}

class PoweredByGoogleImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: AlignmentDirectional.centerEnd,
        color: AppColors.PRIMARY_LIGHT_COLOR,
        padding: const EdgeInsetsDirectional.only(start: 25, top: 15, bottom: 10, end: 25),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "powered_by".tr,
              style: TextStyle(
                color: AppColors.BLACK_TEXT_COLOR,
                fontSize: AppDimen.text_size_12,
                fontFamily: AppFont.font,
              ),
            ),
            const SizedBox(width: 5),
            Image.asset(
              poweredGooglePng,
              height: 15,
            ),
          ],
        ));
  }
}

class PredictionsListView extends StatelessWidget {
  final List<Map<String, dynamic>> predictions;
  final ValueChanged<Map<String, dynamic>>? onTap;
  final bool isRegister;
  final _scrollController = new ScrollController();
  Widget listFooter;

  PredictionsListView(
      {required this.predictions, required this.listFooter, required this.onTap, this.isRegister = false});

  @override
  Widget build(BuildContext context) {
    return PlacesAutocompleteWidget.isRegister
        ? ListView.builder(
            itemCount: predictions.length,
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ScrollPhysics(),
            itemBuilder: (context, index) {
              return Column(
                children: <Widget>[
                  PredictionTile(prediction: predictions[index], onTap: onTap),
                  ColoredBox(
                      color: AppColors.PRIMARY_LIGHT_COLOR,
                      child: Divider(
                        height: 1.1,
                        color: AppColors.DIVIDER_COLOR,
                      )),
                  predictions.length >= 1 && index == predictions.length - 1
                      ? PoweredByGoogleImage()
                      : const SizedBox.shrink(),
                ],
              );
            })
        : WidgetSize(
            onChange: (Size size) {
              print("placespredictioms:${size.height}");
            },
            child: Container(
              height: MediaQuery.of(context).size.height -
                  (MediaQuery.of(context).viewInsets.bottom != 0.0
                      ? MediaQuery.of(context).viewInsets.bottom
                      : 300),
              child: ListView.builder(
                  itemCount: predictions.length,
                  controller: _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        PredictionTile(prediction: predictions[index], onTap: onTap),
                        predictions.length >= 1 && index == predictions.length - 1
                            ? const SizedBox.shrink()
                            : Container(
                                padding: const EdgeInsetsDirectional.symmetric(horizontal: 25),
                                color: AppColors.PRIMARY_LIGHT_COLOR,
                                child: Divider(
                                  height: 1.1,
                                  thickness: 1.1,
                                  color: AppColors.DIVIDER_COLOR,
                                )),
                        predictions.length >= 1 && index == predictions.length - 1
                            ? PoweredByGoogleImage()
                            : const SizedBox.shrink(),
                        predictions.length >= 1 && index == predictions.length - 1
                            ? listFooter
                            : const SizedBox.shrink(),
                      ],
                    );
                  }),
            ),
          );
  }
}

class PredictionTile extends StatelessWidget {
  final Map<String, dynamic> prediction;
  final ValueChanged<Map<String, dynamic>>? onTap;

  PredictionTile({required this.prediction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!(prediction);
        }
      },
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 15.0),
        color: AppColors.PRIMARY_LIGHT_COLOR,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: PlacesAutocompleteWidget.isRegister ? 20 : 25,
            ),
            SvgPicture.asset(
              updatedLocationPredictionSvg,
            ),
            const SizedBox(width: 10),
            Flexible(
                child: HighlightText(
              text: prediction['description'] ?? "",
              highlight: PlacesAutocompleteState.queryTextController!.text,
              style: TextStyle(
                color: AppColors.BLACK_TEXT_COLOR,
                fontWeight: FontWeight.w500,
                fontFamily: AppFont.font,
                fontSize: PlacesAutocompleteWidget.isRegister ? AppDimen.text_size_16 : AppDimen.text_size_14,
              ),
              highlightStyle: TextStyle(
                color: AppColors.BLACK_TEXT_COLOR,
                fontWeight: FontWeight.w500,
                fontFamily: AppFont.font,
                fontSize: PlacesAutocompleteWidget.isRegister ? AppDimen.text_size_16 : AppDimen.text_size_14,
              ),
            )),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

class HighlightText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle style;
  final TextStyle highlightStyle;

  const HighlightText({
    Key? key,
    required this.text,
    required this.highlight,
    required this.style,
    required this.highlightStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String text = this.text ?? '';
    if ((highlight?.isEmpty ?? true) || text.isEmpty) {
      return Text(text, style: style);
    }

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight;
    do {
      indexOfHighlight = text.indexOf(highlight, start);
      if (indexOfHighlight < 0) {
        spans.add(_normalSpan(text.substring(start, text.length)));
        break;
      }
      if (indexOfHighlight == start) {
        spans.add(_highlightSpan(highlight));
        start += highlight.length;
      } else {
        spans.add(_normalSpan(text.substring(start, indexOfHighlight)));
        spans.add(_highlightSpan(highlight));
        start = indexOfHighlight + highlight.length;
      }
    } while (true);

    return Text.rich(TextSpan(children: spans));
  }

  TextSpan _highlightSpan(String content) {
    return TextSpan(text: content, style: highlightStyle);
  }

  TextSpan _normalSpan(String content) {
    return TextSpan(text: content, style: style);
  }
}

class PlacesAutocompleteState extends State<PlacesAutocompleteWidget> with TickerProviderStateMixin {
  static TextEditingController? queryTextController;
  static bool focus = false;
  static List<Map<String, dynamic>>? response;
  BaseController baseController = Get.find();
  static SelectLocationEnum? selectLocationEnum;
  Timer? queryFetchTimer;
  String previousSearch = "";
  /// Set to true while a prediction is being processed (lat/lng fetch + direction drawing)
  /// to prevent the text controller listener from triggering a redundant Places API call.
  static bool isSelectingPrediction = false;
  static int activeStopIndex = 0;

  @override
  void initState() {
    super.initState();
    queryTextController = TextEditingController(text: "");
    globals.placeSearchingController.value = false;
    setListener();
  }

  void setListener() {
    queryTextController?.addListener(onQueryChange);
  }

  void onQueryChange() {
    debugPrint(
        'queryTextController?.text: ${queryTextController?.text} --- ${globals.placeSearchingController.value} -- ${isSelectingPrediction}');
    // Suppress Places API call while a prediction is being selected and direction is being drawn.
    if (isSelectingPrediction) return;
    if (queryTextController?.text != null && queryTextController!.text.isNotEmpty) {
        globals.placeSearchingController.value = true;
        queryFetchTimer?.cancel();
        queryFetchTimer = Timer(Duration(seconds: 1), () {
          if (queryTextController?.text != null &&
              (queryTextController?.text.isNotEmpty ?? false))
            baseController.SearchPlaces(
                PlacesAutocompleteState.queryTextController!.text,
                onResponse: onResponse, onResponseError: onResponseError);
          else {
            globals.locationList.clear();
            globals.placeSearchingController.value = false;
          }
          previousSearch = PlacesAutocompleteState.queryTextController!.text;
        });

    } else {
      queryFetchTimer?.cancel();
      globals.locationList.clear();
      globals.placeSearchingController.value = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    queryTextController?.removeListener(onQueryChange);
  }

  void onResponseError(String errormessage) {
    if (!mounted) return;
    response = [];
    globals.placeSearchingController.value = false;
  }

  @mustCallSuper
  void onResponse(List<Map<String, dynamic>> res) {
    if (!mounted) return;

    response = res;
    globals.placeSearchingController.value = false;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "PlacesAutocompleteState.placeSearchingController.value: ${globals.placeSearchingController.value}");
    return const SizedBox.shrink();
  }
}