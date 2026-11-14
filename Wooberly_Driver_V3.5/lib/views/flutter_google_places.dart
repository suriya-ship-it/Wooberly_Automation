import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:uuid/uuid.dart';

import '../controller/base_controller.dart';
import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import 'package:http/http.dart' as http;



bool? searching;
var uuid = Uuid();
var sessionId = "";

class PlacesAutocompleteWidget extends StatefulWidget {
  final String? apiKey;
  static String hint = "Search Location";
  static bool isRegister = false;


  PlacesAutocompleteWidget(
      {required this.apiKey,
      Key? key,})
      : super(key: key);

  @override
  State<PlacesAutocompleteWidget> createState() {
    return _PlacesAutocompleteScaffoldState();
  }

  static PlacesAutocompleteState? of(BuildContext context) =>
      context.findAncestorStateOfType<PlacesAutocompleteState>();
}

class _PlacesAutocompleteScaffoldState extends PlacesAutocompleteState {
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: AppBarPlacesAutoCompleteTextField());
    final body = PlacesAutocompleteResult(
      onTap: Navigator.of(context).pop,
    );
    return Scaffold(appBar: appBar, body: body);
  }
}



class PlacesAutocompleteResult extends StatefulWidget {
  final ValueChanged<Map<String,dynamic>>? onTap;
  final Widget? listfooter;

  PlacesAutocompleteResult({this.onTap, this.listfooter});

  @override
  _PlacesAutocompleteResult createState() => _PlacesAutocompleteResult();
}

class _PlacesAutocompleteResult extends State<PlacesAutocompleteResult> {
  @override
  Widget build(BuildContext context) {
    final state = PlacesAutocompleteWidget.of(context);
    assert(state != null);
    if (PlacesAutocompleteState.queryTextController!.text.isEmpty ||
        PlacesAutocompleteState.response == null ||
        PlacesAutocompleteState.response!.isEmpty) {
      final children = <Widget>[];
      if (PlacesAutocompleteState.searching!) {}
      return Stack(children: children);
    }
    return PredictionsListView(
      listfooter: widget.listfooter!,
      predictions: PlacesAutocompleteState.response!,
      onTap: widget.onTap!,
    );
  }
}

class AppBarPlacesAutoCompleteTextField extends StatefulWidget {
  bool avoidUnderline;
  String hintText;

  AppBarPlacesAutoCompleteTextField({
    this.avoidUnderline = false,
    this.hintText = "",
  });

  @override
  _AppBarPlacesAutoCompleteTextFieldState createState() =>
      _AppBarPlacesAutoCompleteTextFieldState();
}

class _AppBarPlacesAutoCompleteTextFieldState
    extends State<AppBarPlacesAutoCompleteTextField> {
  @override
  void initState() {
    PlacesAutocompleteWidget.hint = widget.hintText;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment:
            !widget.avoidUnderline ? Alignment.topLeft : Alignment.topLeft,
        margin: !widget.avoidUnderline
            ? const EdgeInsets.only(left: 20.0, top: 0.0, right: 20.0, bottom: 20.0)
            :  const EdgeInsetsDirectional.only(
                start: 10.0, top: 0.0, end: 0.0, bottom: 2.0),
        child: TextField(
          controller: PlacesAutocompleteState.queryTextController,
          autofocus: PlacesAutocompleteState.focus,
          textInputAction: TextInputAction.search,
          style: TextStyle(
              color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
              fontWeight: FontWeight.w500,
              fontSize: PlacesAutocompleteWidget.isRegister
                  ? AppDimen.text_size_16
                  : AppDimen.text_size_14,
              fontFamily: AppFont.font),
          decoration: InputDecoration(
            hintText: PlacesAutocompleteWidget.hint,
            hintStyle: TextStyle(
              color: AppColors.HIND_TEXT_COLOR,
              fontWeight: FontWeight.w500,
              fontSize: PlacesAutocompleteWidget.isRegister
                  ? AppDimen.text_size_16
                  : AppDimen.text_size_14,
            ),
            border: !widget.avoidUnderline
                ? new UnderlineInputBorder(
                    borderSide: new BorderSide(
                      color: AppColors.SEARCH_TEXT_COLOR,
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
        padding: const EdgeInsetsDirectional.only(top: 15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "powered_by".tr,
              style: TextStyle(
                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
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
  final List<Map<String,dynamic>> predictions;
  final ValueChanged<Map<String,dynamic>> onTap;
  final bool? isRegister;

  final _scrollController = new ScrollController();
  Widget listfooter;

  PredictionsListView(
      {required this.predictions,
      required this.listfooter,
      required this.onTap,
      this.isRegister});

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
    return PlacesAutocompleteWidget.isRegister
        ? ListView.builder(
            itemCount: predictions.length,
            controller: _scrollController,
            itemBuilder: (context, index) {
              return Column(
                children: <Widget>[
                  PredictionTile(prediction: predictions[index], onTap: onTap),
                  Divider(
                    height: 5,
                    color: AppColors.DIVIDER_COLOR,
                  ),
                  predictions.length >= 1 && index == predictions.length - 1
                      ? PoweredByGoogleImage()
                      : const SizedBox.shrink(),
                ],
              );
            })
        : Container(
            margin: const EdgeInsetsDirectional.only(start: 0, top: 10, bottom: 10),
            decoration: BoxDecoration(
                color: AppColors.PRIMARY_COLOR_WHITE,
                borderRadius: BorderRadius.all(Radius.circular(3))),
            child: ListView.builder(
                itemCount: predictions.length,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  return Column(
                    children: <Widget>[
                      PredictionTile(
                          prediction: predictions[index], onTap: onTap),
                      Divider(
                        height: 5,
                        color: AppColors.GRAY,
                      ),
                      predictions.length >= 1 && index == predictions.length - 1
                          ? PoweredByGoogleImage()
                          : const SizedBox.shrink(),
                      predictions.length >= 1 && index == predictions.length - 1
                          ? listfooter
                          : const SizedBox.shrink(),
                    ],
                  );
                }),
          );
  }
}

class PredictionTile extends StatelessWidget {
  final Map<String,dynamic> prediction;
  final ValueChanged<Map<String,dynamic>> onTap;

  PredictionTile({required this.prediction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap(prediction);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
            top: PlacesAutocompleteWidget.isRegister ? 15 : 10.0,
            bottom: PlacesAutocompleteWidget.isRegister ? 15 : 10.0),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: PlacesAutocompleteWidget.isRegister ? 10 : 15,
            ),
            SvgPicture.asset(
              updatedLocationPredictionSvg,
            ),
           const SizedBox(
              width: 10,
            ),
            Flexible(
                child: HighlightText(
              text:prediction['description'] ?? "",
              highlight: PlacesAutocompleteState.queryTextController!.text,
              style: TextStyle(
                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                fontWeight: FontWeight.w500,
                fontFamily: AppFont.font,
                fontSize: PlacesAutocompleteWidget.isRegister
                    ? AppDimen.text_size_16
                    : AppDimen.text_size_14,
              ),
              highlightStyle: TextStyle(
                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                fontWeight: FontWeight.w500,
                fontFamily: AppFont.font,
                fontSize: PlacesAutocompleteWidget.isRegister
                    ? AppDimen.text_size_16
                    : AppDimen.text_size_14,
              ),
            )),
           const SizedBox(
              width: 10,
            ),
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

enum Mode { overlay, fullscreen }
abstract class PlacesAutocompleteState extends State<PlacesAutocompleteWidget> {
  static TextEditingController? queryTextController;
  static bool focus = false;
  static final rxPlacesAutocompleteRefreshController = ReactiveVariable("rxPlacesAutocompleteRefreshController", false);
  static List<Map<String,dynamic>>? response;
  static bool? searching;
  final rxQueryBehavior = ''.obs;

  @override
  void initState() {
    super.initState();
    queryTextController = TextEditingController(text: "");
    searching = false;
    setListener();
    rxQueryBehavior.stream.debounceTime(const Duration(milliseconds: 2000)).listen(doSearch);
  }

  Future<dynamic> doSearch(String value) async {
    if (mounted && value.isNotEmpty) {
      if(sessionId.isEmpty) {
        sessionId = uuid.v4();
      }
      searching = true;
      String secureKey = await App().getSecurityKey();
      var url = globals.autoCompleteUrl;
      dynamic response;
      Map<String, String>? headers;
      var body;
      if(globals.authToken != null){
        Map<String, String>? headers = {
          "Content-Type":"application/json",
          "auth" : globals.authToken ?? ""
        };
        body = {
          "input" : value,
          "platformSecretKey" : secureKey,
          "sessionToken": sessionId
        };
        response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
      }
      else{
        headers = {
          "Content-Type":"application/json",
        };
        body = {
          "input" : value,
          "platformSecretKey" : secureKey,
          "sessionToken": sessionId
        };
        response = await http.post(Uri.parse(url), headers: headers,body: jsonEncode(body));
      }

      List<Map<String,dynamic>> locationList = [];

      var json = jsonDecode(response.body);
      locationList.clear();

      if(json['response']['suggestions'] !=null && json['response']['suggestions'].isNotEmpty) {
        for (var item in json['response']['suggestions']) {
          Map<String, String> locationItem = {};
          locationItem['description'] = item['placePrediction']['text']['text'];
          locationItem['place_id'] = item['placePrediction']['placeId'];
          locationList.add(locationItem);
        }
        onResponse(locationList);
      }else if(json['errorMessage'] !=null && json['errorMessage'].isNotEmpty){
        App().toast.show(context: context, message: json['errorMessage']);
        onResponseError(json['errorMessage'].toString());
      }
      else if(json['errorMessage']['error']['message'] != null && json['errorMessage']['error']['message'].isNotEmpty){
        App().toast.show(context: context, message: json['errorMessage']['error']['message']);
        onResponseError(json['errorMessage']['error']['message'].toString());
      }
    }
  }

  void setListener() {
    queryTextController!.addListener(onQueryChange);
  }

  void onQueryChange() {
    rxQueryBehavior.value = queryTextController!.text;
  }

  @override
  void dispose() {
    super.dispose();
    rxQueryBehavior.close();
    queryTextController!.removeListener(onQueryChange);
  }

  void onResponseError(String errormessage) {
    if (!mounted) return;
    (() {
      response = [];
      searching = false;
    });
  }

  void onResponse(List<Map<String,dynamic>> res) {
    if (!mounted) return;
    response = res;
    searching = false;
    globals.baseController.change(rxVariable: PlacesAutocompleteState.rxPlacesAutocompleteRefreshController, value: true);
  }

}