part of '../controllers/base_controller.dart';

extension BaseControllerPart2 on BaseController{

  Future<File?> getDownloadedFile({required String url, required String lang, isUpdate = false}) async {
   debugPrint("getDownloadedFileurl: ${url}");
   if(url.isNotEmpty) {
     String filename = url
         .split("/")
         .last;
     appDocumentsDir = await getApplicationDocumentsDirectory();
     String filePath = '${appDocumentsDir.path}/$filename';
     File file = File(filePath);
     http.Response response = await http.get(Uri.parse(url));
     await file.writeAsBytes(response.bodyBytes);
     downloadedLanguages.add(lang);
     preferences.downloadedLanguages= downloadedLanguages.join(',');
     return file;
   }
   return null;
  }

  Future<String> getAILanguageList({bool? isShowLoader}) async {
    if(isShowLoader !=null)
      globals.isLoaderShow = isShowLoader;
    graphQlObject.graphQLClientWithHeader.cache.store.reset();
    var variables = <String, dynamic>{
      "currentPage": AILangListCurrentPage,
    };
    log("AILanglist: params ${variables} --- ${globals.isLoaderShow}");
    Map<String, dynamic>? _langlistResult = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getAILanguages_query", variables);

    if (_langlistResult != null && _langlistResult["getAllMobileLanguage"]["status"] == 200) {
      AILanglistCount =_langlistResult["getAllMobileLanguage"]['count'];
      var results = _langlistResult["getAllMobileLanguage"]['results'] as List;

      if(AILangListCurrentPage == 1){
        AILanglist.clear();
      }
      for(Map<String, dynamic> item in results){
        if(item['isAIPreferredLanguage']){
          AILanglist.add({
            'language': item['language'] as String,
            'languageCode': item['languageCode'] as String,
          });
        }
      }
      log("AILanglist: ${AILanglist}");
      AILanglist.refresh();
      return '';
    } else {
      return _langlistResult !=null ?_langlistResult["getAllMobileLanguage"]["errorMessage"] : 'offline';
    }
  }

  Future<void> getUserAILanguage({bool? isShowLoader}) async {
    if(isShowLoader !=null)
      globals.isLoaderShow = isShowLoader;
    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "getCurrentAILanguage_query",
        null);
    if (_login_result != null) {
      if (_login_result["userAccount"]["status"] == 200) {
        globals.aiPreferredLanguage = _login_result["userAccount"]["result"]["aiPreferredLanguage"] ?? '';
        globals.preferredCurrency = _login_result["userAccount"]["result"]["preferredCurrency"];
        NumberFormat _numberFormat = new NumberFormat("#,##0.00", "en_US");
        globals.currencySymbol = _numberFormat.simpleCurrencySymbol(globals.preferredCurrency);
        globals.currencySymbol = getCurrencySybmol(
            globals.preferredCurrency, globals.currencySymbol);
      }
    }
  }

  Future<String> updateAILanguage(String fieldName, String fieldValue) async {
    globals.isContinuousLoading = true;
    var variables = <String, dynamic>{
      "userId": globals.userid,
      "fieldName": fieldName,
      "fieldValue": fieldValue,
      "deviceType": globals.deviceName,
      "deviceId": globals.deviceId
    };

    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "userUpdate_mutation",
        variables);
    if (_login_result != null) {
      if (_login_result["userUpdate"]["status"] == 200) {
        globals.setButtonIdle();
        return "";
      } else if (_login_result["userUpdate"]["status"] == 500) {
        globals.setButtonIdle();
        return "timeout";
      } else {
        globals.setButtonIdle();
        return _login_result["userUpdate"]["errorMessage"];
      }
    } else
      return "offline";
  }

  Map<String, dynamic> getDateTimeValue(
      [Map<String, dynamic>? dateTimeValue, DateTime? now]) {
    if (dateTimeValue == null) dateTimeValue = Map<String, dynamic>();
    if (now == null) now = DateTime.now();
    final DateFormat formatter = DateFormat(globals.dateFormat, globals.defaultLanguageCode);
    final String dateValue = formatter.format(now);
    final String dayValue = DateFormat('EEEE', globals.defaultLanguageCode).format(now);
    final String startTimeValue = "${now.hour}.${now.minute}";
    dateTimeValue["dateValue"] = dateValue;
    dateTimeValue["dayValue"] = dayValue;
    dateTimeValue["startTimeValue"] = startTimeValue;

    return dateTimeValue;
  }
  void showUnclosableSnackBar(BuildContext context, String value) {
    ScaffoldMessenger.of(context)
        .showSnackBar(new SnackBar(
      content: new Text(value,
          style: TextStyle(
            color: AppColors.WHITE_TEXT_COLOR,
            fontWeight: FontWeight.w300,
            fontSize: AppDimen.text_size_14,
            fontFamily: AppFont.font,
          )),
      duration: Duration(hours: 2),
    ))
        .closed
        .then((reason) {
      if (reason == SnackBarClosedReason.swipe)
        showUnclosableSnackBar(context, value);
    });
  }

  SearchPlaces(String value,{onResponse, onResponseError}) async {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_SearchPlaces ${point} --- ${sessionId}');
    if(sessionId.isEmpty) {
      sessionId = uuid.v4();
    }
    var json;
    var cachedData = preferences.getCachedSearchPlaces(value);
    if (cachedData != null) {
      print('test9_SearchPlaces loaded from preference for searchKey: $value');
      json = cachedData;
    } else {
      String secureKey = await getSecurityKey();
      var url = globals.autoCompleteUrl;
      http.Response response;
      var body;
      Map<String, String>? headers = {
        "Content-Type":"application/json",
      };
      if(globals.authToken != null)
        headers[ "auth"] = globals.authToken!;
      body = {
        "input" : value,
        "platformSecretKey" : secureKey,
      "sessionToken": sessionId

    };

      response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
      json = convert.jsonDecode(response.body);

      if (json != null && json['response'] != null && json['response']['suggestions'] != null) {
        await preferences.saveCachedSearchPlaces(value, json);
      }
    }

    //   var json = jsonDecode('{"status":200,"response":{"suggestions":[{"placePrediction":{"place":"places/ChIJL_NhOY4qQocRBeerF9lKnvI","placeId":"ChIJL_NhOY4qQocRBeerF9lKnvI","text":{"text":"Meeker, CO, USA","matches":[{"endOffset":3}]},"structuredFormat":{"mainText":{"text":"Meeker","matches":[{"endOffset":3}]},"secondaryText":{"text":"CO, USA"}},"types":["political","locality","geocode"]}},{"placePrediction":{"place":"places/ChIJJWO2V_RkDDkRXr6mhzOo-kI","placeId":"ChIJJWO2V_RkDDkRXr6mhzOo-kI","text":{"text":"Meerut, Uttar Pradesh, India","matches":[{"endOffset":3}]},"structuredFormat":{"mainText":{"text":"Meerut","matches":[{"endOffset":3}]},"secondaryText":{"text":"Uttar Pradesh, India"}},"types":["geocode","locality","political"]}},{"placePrediction":{"place":"places/ChIJ47o3LvRnTFMRRh-XBgBLZb4","placeId":"ChIJ47o3LvRnTFMRRh-XBgBLZb4","text":{"text":"Meeteetse, WY, USA","matches":[{"endOffset":3}]},"structuredFormat":{"mainText":{"text":"Meeteetse","matches":[{"endOffset":3}]},"secondaryText":{"text":"WY, USA"}},"types":["geocode","political","locality"]}},{"placePrediction":{"place":"places/ChIJe3XtZL3Fs4cRcvQiLgJHBrI","placeId":"ChIJe3XtZL3Fs4cRcvQiLgJHBrI","text":{"text":"Meeker, OK, USA","matches":[{"endOffset":3}]},"structuredFormat":{"mainText":{"text":"Meeker","matches":[{"endOffset":3}]},"secondaryText":{"text":"OK, USA"}},"types":["geocode","locality","political"]}},{"placePrediction":{"place":"places/ChIJP1edGZG2uEcRr8cLtESpXOs","placeId":"ChIJP1edGZG2uEcRr8cLtESpXOs","text":{"text":"Meerbusch, Germany","matches":[{"endOffset":3}]},"structuredFormat":{"mainText":{"text":"Meerbusch","matches":[{"endOffset":3}]},"secondaryText":{"text":"Germany"}},"types":["locality","geocode","political"]}}]},"errorMessage":null}');
    // log("places result: ${json}");

    globals.locationList.clear();

    if(json != null && json['response'] != null && json['response']['suggestions'] !=null && json['response']['suggestions'].isNotEmpty) {
      for (var item in json['response']['suggestions']) {
        Map<String, String> locationItem = {};
        locationItem['description'] = item['placePrediction']['text']['text'];
        locationItem['place_id'] = item['placePrediction']['placeId'];
        globals.locationList.add(locationItem);
      }
      onResponse( globals.locationList);
    }else if(json != null && json['errorMessage'] !=null && json['errorMessage'] is String && (json['errorMessage'] as String).isNotEmpty){
      debugPrint("json: ${json}");
      showInSnackBar(json['errorMessage']);
    }
    else if(json != null && json['errorMessage'] != null && json['errorMessage']['error'] != null && json['errorMessage']['error']['message'] != null && json['errorMessage']['error']['message'].isNotEmpty){
      debugPrint("json: ${json}");
      showInSnackBar(json['errorMessage']['error']['message']);
      onResponseError(json['errorMessage']['error']['message']);
    }
    else if(json != null && json['error'] !=null && json['error']['message'] !=null &&  json['error']['message'].toString().isNotEmpty){
      showInSnackBar( json['error']['message']);
      onResponseError(json['error']['message']);
      debugPrint("json: ${json}");
    }
  }

  Widget linearLoader(){
    return  SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        backgroundColor: Colors.black12,
        valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.PRIMARY_DARK_COLOR),
      ),
    );
  }

  Future<LatLng> findPlaces(dynamic placeId) async {
    final point=StackTrace.current.toString().split('\n')[1];
    print('test9_findPlaces ${point} --- ${sessionId}');
    String secureKey = await getSecurityKey();
    var url = globals.placeSearchUrl;
    Map<String, String>? headers;
    var body;
    if(globals.authToken != null){
      headers = {
        "Content-Type": "application/json",
        "auth": globals.authToken ?? ""
      };
      body = {
        "placeId": placeId,
        "platformSecretKey": secureKey,
        "sessionToken": sessionId
      };
    }
    else{
      headers = {
        "Content-Type": "application/json",
      };
      body = {
        "placeId": placeId,
        "platformSecretKey": secureKey
      };
    }
    final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: convert.jsonEncode(body)
    );
    var json = convert.jsonDecode(response.body);
    log("findPlacesjson: ${json}");

    sessionId = "";
    if (json["response"]?["location"] != null) {
      final lat = json["response"]["location"]["latitude"];
      final lng = json["response"]["location"]["longitude"];
      _getAddressFromPlaceDetails(json["response"]);
      return LatLng(lat, lng);
    }
    else if(json['errorMessage'] !=null && json['errorMessage'].isNotEmpty){
      debugPrint("json: ${json}");
      toast.show( message: json['errorMessage'], context: Get.context!);
      return LatLng(0.0, 0.0);
    }
    else if(json['errorMessage']['error']['message'] != null && json['errorMessage']['error']['message'].isNotEmpty){
      debugPrint("json: ${json}");
      toast.show(context: Get.context!, message: json['errorMessage']['error']['message']);
      return LatLng(0.0, 0.0);
    }
    return LatLng(0.0, 0.0);
  }

  void _getAddressFromPlaceDetails(Map<String, dynamic> placeDetails) {
    final addressComponents = placeDetails['address_components'] as List<dynamic>?;

    if (addressComponents == null) return;

    String? city;
    String? state;
    String? zipcode;
    String? country;

    for (var component in addressComponents) {
      final types = component['types'] as List<dynamic>;

      // 1. Get City
      if (types.contains('locality')) {
        city = component['long_name'];
      }
      // Fallback for cities wrapped in sublocalities
      else if (city == null && types.contains('sublocality_level_1')) {
        city = component['long_name'];
      }

      // 2. Get State
      if (types.contains('administrative_area_level_1')) {
        state = component['short_name']; // Use 'long_name' if you want full name
      }

      // 3. Get Zipcode
      if (types.contains('postal_code')) {
        zipcode = component['long_name'];
      }

      // 4. Get Country
      if (types.contains('country')) {
        country = component['short_name']; // e.g., 'US', 'IN'
      }
    }
    placeDetails['city'] = city ?? '';
    placeDetails['state'] = state ?? '';
    placeDetails['zipcode'] = zipcode ?? '';
    placeDetails['country'] = country ?? '';

  }
  getAppVersion() async {
    try {
      globals.versionCode = await locationChannel.invokeMethod('appversion');

    } on PlatformException catch (e) {
      debugPrint("Failed to get location level: '${e.message}'.");
      return "";
    }
  }
  Future<bool> changeMode() async {
    try {
      bool location = await locationChannel.invokeMethod(
          'changeThemeMode', {"isDarkMode": globals.isDarkTheme.toString()});
      return location;
    } on PlatformException catch (e) {
      debugPrint("Failed to get location service: '${e.message}'.");
      return false;
    }
  }
  getCurrencyListForPaypal() async {
    CurrencyModel currencyModel;
    Map<String, dynamic>? _currency_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getAllCurrencies_query", null);
    if(_currency_result !=null) {
      currencyModel = CurrencyModel.fromJson(_currency_result);
      if (currencyModel.getAllCurrencies?.status?.compareTo("200") == 0) {
        List<CurrencyResults> result = currencyModel.getAllCurrencies?.results ?? [];
        for(var element in result){
          if(element.isPayment == true && element.symbol != null){
            globals.paypalCurrencies.add(element.symbol!);
          }
        }
      }
    }
  }

  Widget getBackIcon() {
    return InkWell(
      onTap: (){
        Get.back();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: AppColors.COMMON_BG_COLOR, shape: BoxShape.circle),
        child: SizedBox(
          width: 12,
          height: 21,
          child: RotatedBox(
            quarterTurns: globals.isRTLLang ? 2:0,
            child: SvgPicture.asset(
              primaryLeftArrow,
              fit: BoxFit.scaleDown,
              colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}