import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wooberly_driver/graphql/graphql_config.dart';

import '../../resources/values/app_lang.dart';
import '../../utils/globals.dart';
import '../base_controller.dart';



class EarningController extends BaseController {
  List<String> earningSection = [today.tr,this_week.tr, this_month.tr,total.tr];
  int selectedEarnType = 0;
  Map<String,dynamic> earningDetails = {};

  getEarnings() async {
    graphQlObject.graphQLClientWithHeader.cache.store.reset();

    Map<String, dynamic>? _earnings_result = await graphQlObject.getQueryValues(
        graphQlObject.graphQLClientWithHeader, "getTotalEarning_query", null);
    if (_earnings_result?["getTotalEarning"]["status"] == 200) {
      String currency = (_earnings_result?["getTotalEarning"]["result"]["currency"]);
      switch(selectedEarnType){
        case 0:
          {
            earningDetails['date'] = DateFormat(dateFormatMMMD).format(DateTime.fromMillisecondsSinceEpoch(int.parse(_earnings_result?["getTotalEarning"]["result"]["todayDate"])));
            earningDetails['trips'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["todayTrips"]).toString()).toStringAsFixed(0);
            earningDetails['tips'] =double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["todayTips"]).toString()).toStringAsFixed(2);
            earningDetails['earning'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["todayEarnings"]).toString()).toStringAsFixed(2);
            earningDetails['duration'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["todayDuration"]).toString()).toStringAsFixed(2);
          };
        case 1:
          {
            earningDetails['date'] = dayDiff(_earnings_result?["getTotalEarning"]["result"]["startDate"], _earnings_result?["getTotalEarning"]["result"]["endDate"]);
            earningDetails['trips'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["weeklyTotalTrips"]).toString()).toStringAsFixed(0);
            earningDetails['tips'] =double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["weeklyTotaltips"]).toString()).toStringAsFixed(2);
            earningDetails['earning'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["weeklyTotalEarnings"]).toString()).toStringAsFixed(2);
            earningDetails['duration'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["weeklyTotalDuration"]).toString()).toStringAsFixed(2);
          };
        case 2:
          {
            earningDetails['date'] = dayDiff(_earnings_result?["getTotalEarning"]["result"]["monthStartDate"], _earnings_result?["getTotalEarning"]["result"]["monthEndDate"]);
            earningDetails['trips'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["monthlyTrips"]).toString()).toStringAsFixed(0);
            earningDetails['tips'] =double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["monthlyTips"]).toString()).toStringAsFixed(2);
            earningDetails['earning'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["monthlyEarnings"]).toString()).toStringAsFixed(2);
            earningDetails['duration'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["monthlyDuration"]).toString()).toStringAsFixed(2);
          };
        case 3:
          {
            earningDetails['date'] = total.tr;
            earningDetails['trips'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["totalTrips"]).toString()).toStringAsFixed(0);
            earningDetails['tips'] =double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["totalTips"]).toString()).toStringAsFixed(2);
            earningDetails['earning'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["totalEarnings"]).toString()).toStringAsFixed(2);
            earningDetails['duration'] = double.parse(getRate(currency, _earnings_result?["getTotalEarning"]["result"]["totalDuration"]).toString()).toStringAsFixed(2);
          };
      }
      return "";
    } else {
      return _earnings_result?["getTotalEarning"]["errorMessage"];
    }
  }

  String dayDiff(String start, String end){
    return "${start} - ${end}";
  }
}