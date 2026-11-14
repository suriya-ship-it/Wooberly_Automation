import 'package:get/get.dart';
import 'package:wooberly_driver/controller/profile_controllers/static_page_controller.dart';
import 'package:wooberly_driver/controller/trip_controllers/earning_controller.dart';
import 'package:wooberly_driver/controller/trip_controllers/payout_controller.dart';
import 'package:wooberly_driver/controller/trip_controllers/trip_controller.dart';
import '../controller/profile_controllers/edit_account_controller.dart';

class TripBinding extends Bindings {
  TripBinding._privateConstructor();
  static final TripBinding _instance = TripBinding._privateConstructor();

  factory TripBinding() {
    return _instance;
  }

  @override
  void dependencies() {
    Get.lazyPut<EarningController>(() => EarningController(), fenix: true);
    Get.lazyPut<PayoutController>(() => PayoutController(), fenix: true);
    Get.lazyPut<TripController>(() => TripController(), fenix: true);
  }
}