part of 'map_main_controller.dart';

extension GraphQLFetchOnController on MapMainController {


  Future<String> sendMessage(String message) async {
    var variables = <String, dynamic>{
      "bookingId": bookingID,
      "message": message,
    };
    try {
      globals.isLoaderShow = false;
      Map<String, dynamic>? msgResult = await graphQlObject.getMutationValues(
          graphQlObject.graphQLClientWithHeader,
          "createThreadMutation",
          variables);
      if (msgResult != null) {
        if (msgResult["createThread"]["status"] == 200) {
          return "";
        } else {
          return msgResult["createThread"]["errorMessage"];
        }
      } else {
        return "offline";
      }
    }  on Exception catch (e, stack) {
      debugPrint("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
      return 'offline';
    }
  }

  Future<String?> getAllThreads(int pageCount) async {
    var variables = <String, dynamic>{
      "bookingId": bookingID,
      "currentPage": pageCount
    };
    try {
      // globals.isLoaderShow = true;
      print("inside getAllThreads");
      Map<String, dynamic>? threadResult =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "getAllThreads",
              variables);
      print("inside getAllThreads11");
      if (threadResult != null) {
        if (threadResult["getAllThreadItems"]["status"] == 200) {
          print("inside getAllThreads11");
          allThreadsResult = ALLThreads.fromJson(threadResult);
          if (allThreadsResult.getAllThreadItems != null)
            threadItems = allThreadsResult.getAllThreadItems ?? GetAllThreadItems();
          if (threadItems.result?.userDetails?.profile?.aiPreferredLanguage != null)
            rideraiPrefLag = threadItems.result!.userDetails!.profile!.aiPreferredLanguage!;
          if (threadItems.result?.threadItems != null &&
              (threadItems?.result?.threadItems?.length ?? 0) > 0) {
            threadItems.result?.threadItems?.forEach((element) {
              if (threadItems.result?.userDetails?.profile?.picture != null) {
                if (globals.userid != element.authorId) {
                  if (riderImage !=
                      (globals.UPLOAD_URL +
                          "/images/avatar/" +
                          (threadItems?.result?.userDetails?.profile?.picture ??
                              ""))) {
                    riderImage = globals.UPLOAD_URL +
                        "/images/avatar/" +
                        threadItems!.result!.userDetails!.profile!.picture!;
                    change(rxVariable: rxPictureChangeController, value: true);
                  }
                }
              } else {
                riderImage = "";
                change(rxVariable: rxPictureChangeController, value: true);
              }
            });
          }
          return "";
        } else if (threadResult["getAllThreadItems"]["status"] == 400) {
          if (threadResult["getAllThreadItems"]["errorMessage"] != null) {
            return threadResult["getAllThreadItems"]["errorMessage"];
          }
        }
      } else {
        return "offline";
      }
    }on Exception catch (e, stack) {
      debugPrint("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
      return 'offline';
    }
  }

  Future<String> getUnreadThreadCount() async {
    var variables = <String, dynamic>{"bookingId": bookingID};
    try {
      Map<String, dynamic>? result = await graphQlObject.getMutationValues(
          graphQlObject.graphQLClientWithHeader,
          "getUnreadThreadCount",
          variables);

      if (result?["getUnreadThreadCount"]["status"] == 200) {
        unreadCount = result?["getUnreadThreadCount"]["count"];
        return "";
      } else if (result?["getUnreadThreadCount"]["status"] == 400) {
        unreadCount = 0;
        return "";
      } else {
        return "something_went_wrong".tr;
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
      return 'offline';
    }
  }

  Future<String> readThreadCount() async {
    var variables = <String, dynamic>{"bookingId": bookingID};
    try {
      globals.isLoaderShow = false;
      Map<String, dynamic>? result = await graphQlObject.getMutationValues(
          graphQlObject.graphQLClientWithHeader,
          "readThreadMutation",
          variables);

      if (result?["readThread"]["status"] == 200 ||
          result?["readThread"]["status"] == 400) {
        unreadCount = 0;
        change(rxVariable: rxUnReadCountController, value: unreadCount);
        return "";
      } else {
        return "something_went_wrong".tr;
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
      return 'offline';
    }
  }

  addMessage(String msg, String time, String userTypeId, String picture, String messageType, int voiceDuration, String audioName, String originalText) {
    ChatMessage newMessage = ChatMessage(
        message: msg, userTypeId: userTypeId, time: time, picture: picture, messageType: messageType, voiceDuration: voiceDuration, audioName: audioName, originalText: originalText);
    messages.insert(0, newMessage);
    // chatController.clear();
    change(rxVariable: rxMessageUpdateController, value: true);
    Timer(Duration(milliseconds: 100),
        () => controller.jumpTo(controller.position.minScrollExtent));
  }


  getCurrencyRates() async {
    Map<String, dynamic>? _currency_rates = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getCurrencyRates_query", null);
    if (_currency_rates?["currency"]["status"] == 200) {
      globals.currencyRates = _currency_rates?["currency"]["result"]["rates"];
      globals.baseCurrency = _currency_rates?["currency"]["result"]["base"];
    }
  }

  Future<String?> getcancelreason() async {
    var variables = <String, dynamic>{
      "userType": 2,
    };
    try {
      Map<String, dynamic>? getcancelreason_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "getCancelReason_query",
              variables);
      if (getcancelreason_result != null) {
        if (getcancelreason_result["getCancelReason"]["status"] == 200) {
          if (cancelReasonList != null) {
            cancelReasonList.clear();
          }
          getCancelReasonModel =
              GetCancelReasonModel.fromJson(getcancelreason_result);
          for (int i = 0;
              i < (getCancelReasonModel?.getCancelReason?.result?.length ?? 0);
              i++) {
            Map<String, String> temp = new HashMap();
            if (getCancelReasonModel?.getCancelReason?.result?[i].isActive ??
                false) {
              temp['id'] =
                  getCancelReasonModel!.getCancelReason!.result![i].id!;
              temp['reason'] =
                  getCancelReasonModel!.getCancelReason!.result![i].reason!;
              cancelReasonList.add(temp);
            }
          }
          Map<String, String> temp2 = new HashMap();
          temp2['id'] = "0";
          temp2['reason'] = other.tr;
          cancelReasonList.add(temp2);

          return "";
        } else if (getcancelreason_result["getCancelReason"]["status"] == 400) {
          return getcancelreason_result["getCancelReason"]["errorMessage"];
        } else {
          return "timeout";
        }
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
      return 'offline';
    }
  }


  Future<String?> updateDriverStatus(bool isActive) async {
    final point=StackTrace.current.toString().split('\n')[1];
    var variables = <String, dynamic>{
      "isActive": isActive,
    };
    debugPrint("updateDriverStatus: ${variables}");
    if (mapLocation.latitude != 0.0 && mapLocation.longitude != 0.0) {
      variables["lat"] = mapLocation.latitude;
      variables["lng"] = mapLocation.longitude;
    }

    if (isActive)
      App().setBgLocationInfo_IOS(
          globals.authToken, globals.userid, globals.deviceId);
    else
      App().setBgLocationInfo_IOS("", "", "");

    PrimaryScaffold.avoidLoader = true;
    Map<String, dynamic>? _login_result = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "updateDriverstatus_mutation",
        variables);
    debugPrint("_getLocation: goonline: ${_login_result} --- ${globals.isActive} --- ${isActive}");
    if (_login_result != null) {
      setLoadingController(false);
      if (_login_result["updateDriverstatus"]["status"] == 200) {
        if(globals.isActive != isActive) {
          globals.isActive = isActive;

          if(globals.isActive == false)
            change(rxVariable: rxOnlineStatus, value: false);
          else
            setDriverStatus(isActive);
        }
        rxRouteController.value = mapLocation;
        return "";
      } else if (_login_result["updateDriverstatus"]["status"] == 500) {
        setLogout(scaffoldContext!);
      } else {
        return _login_result["updateDriverstatus"]["errorMessage"];
      }
    } else {
      return "null";
    }
  }

  Future<String> getTripSummary() async {
    Map<String, dynamic>? _trip_summary = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "tripSummary_query", null);

    if (_trip_summary?["TotalBooking"]["status"] == 200) {
      totalTrips = _trip_summary?["TotalBooking"]["results"]["totalBookings"];
      totalEarings = _trip_summary?["TotalBooking"]["results"]["totalIncome"];
      //hide due to double time reload show map as blinking
      change(rxVariable: rxIsPrivateController, value: false);
      return "";
    } else {
      return _trip_summary?["TotalBooking"]["errorMessage"];
    }
  }

  Future<String> writeReview() async {
    try {
      var variables = <String, dynamic>{
        "userId": riderID,
        "bookingId": bookingID,
        "authorId": globals.userid,
        "ratings": rxStarRatingController.value,
        "reviewContent": ""
      };
debugPrint("writeReview varibale: ${variables}");
      Map<String, dynamic>? _review_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "riderReview_mutation",
              variables);
      debugPrint("writeReview _review_result: ${_review_result}");
      if (_review_result != null) {
        if (_review_result["WriteReviews"]["status"] == 200) {
          return "";
        } else {
          return "something_went_wrong".tr;
        }
      } else {
        return "offline";
      }
    } on Exception catch (e, stack) {
      print("Error: $e");
      FirebaseCrashlytics.instance.recordError(e, stack);
      return 'offline';
    }
  }

  Future<String> updateCurrentLoc(LatLng curlocation) async {
    if (mapLocation.latitude != 0.0 && mapLocation.longitude != 0.0) {
      graphQlObject.graphQLClientWithHeader;

      var variables = <String, dynamic>{
        "lat": curlocation.latitude,
        "lng": curlocation.longitude
      };
      PrimaryScaffold.avoidLoader = true;
debugPrint("updateCurrentLoc: ${variables}");
      Map<String, dynamic>? _login_result =
          await graphQlObject.getMutationValues(
              graphQlObject.graphQLClientWithHeader,
              "updateDriverLocation_mutation",
              variables,false);
      debugPrint("updateCurrentLoc: _login_result: ${_login_result}");
      if (_login_result != null) {
        if (_login_result["updateDriverLocation"]["status"] == 200) {
          return "";
        } else if (_login_result["updateDriverLocation"]["status"] == 500) {
          return "timeout";
        } else {
          return _login_result["updateDriverLocation"]["errorMessage"];
        }
      }
    }
    return "";
  }


  Future<String?> getPaymentMethods() async {
    if (graphQlObject.graphQLClient != null) {
      try {
        Map<String, dynamic>? _currency_rates =
            await graphQlObject.getQueryValues(
                graphQlObject.graphQLClientWithHeader,
                "getPaymentMethods_Query",
                null);
        if (_currency_rates != null &&
            _currency_rates["getPaymentMethods"]["status"] == 200) {
          globals.paymentMethods.clear();
          for (dynamic paymentItem in _currency_rates["getPaymentMethods"]
              ["results"]) {
            if (paymentItem is Map<String, dynamic>) {
              globals.paymentMethods.add(paymentItem["paymentType"]);
            }
          }
          return "";
        }
      } on Exception catch (e, stack) {
        print("Error: $e");
        FirebaseCrashlytics.instance.recordError(e, stack);
        return 'offline';
      }
    }
  }

  Future<String?> getPaymentSettings() async {
    App().getSecurityKey().then((securityKey) async {
      if (graphQlObject.graphQLClient != null) {
        var variables = <String, dynamic>{
          "securityKey": securityKey
        };

        graphQlObject.graphQLClient.cache.store.reset();
        try {
          Map<String, dynamic>? paymentResult =
              await graphQlObject.getQueryValues(graphQlObject.graphQLClient,
                  "getSecureSiteSettings", variables);
          if (paymentResult?["getSecureSiteSettings"]["status"] == 200) {
            Map<String,dynamic> walletoption ={};
            walletoption.addAll(globals.driverWalletOptionController.value);
            final results = paymentResult?["getSecureSiteSettings"]?["results"];

            if (results is Iterable) {
              for (var element in results) {
                final name = element["name"];
                final value = element["value"];

                switch (name) {
                  case "stripePublishableKey":
                    globals.stripePublishableKey = value;
                    break;
                  case "driverWalletOption":
                    walletoption["driverWalletOption"] = value;
                    break;
                  case "walletFlow":
                    walletoption["walletFlow"] = value;
                    break;
                  case "isVoiceAIFeature":
                    globals.isVoiceChatEnable = (value == 'true');
                    break;
                  case "isVoiceTranslatorFeature":
                    globals.isVoiceTranslatorEnable = (value == 'true');
                    break;
                }
              }
            }
            globals.driverWalletOptionController.value = walletoption;


            App().getAudioPlayerCache();
            if( paymentSettingTimer !=null){
              Future.delayed(Duration(seconds: 1)).then((value) {
                paymentSettingTimer?.cancel();
                paymentSettingTimer = null;
              });
            }
            return "";
          } else {
            if( paymentSettingTimer !=null){
              Future.delayed(Duration(seconds: 1)).then((value) {
                paymentSettingTimer?.cancel();
                paymentSettingTimer = null;
              });
            }
            return "null";
          }
        } on Exception catch (e, stack) {
          print("Error: $e");
          FirebaseCrashlytics.instance.recordError(e, stack);
          return 'offline';
        }
      }
    });
  }
}