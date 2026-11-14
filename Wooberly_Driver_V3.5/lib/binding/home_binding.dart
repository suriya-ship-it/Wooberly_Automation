import 'package:get/get.dart';
import '../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../controller/profile_controllers/edit_account_controller.dart';
import '../controller/profile_controllers/static_page_controller.dart';
import '../controller/trip_controllers/earning_controller.dart';
import '../controller/trip_controllers/payout_controller.dart';
import '../controller/trip_controllers/trip_controller.dart';

class HomeBinding extends Bindings {
  HomeBinding._privateConstructor();
  static final HomeBinding _instance = HomeBinding._privateConstructor();

  factory HomeBinding() {
    return _instance;
  }

  @override
  void dependencies() {
    Get.lazyPut<StaticPageController>(() => StaticPageController(), fenix: true);
    Get.lazyPut<EarningController>(() => EarningController(), fenix: true);
    Get.lazyPut<PayoutController>(() => PayoutController(), fenix: true);
    Get.lazyPut<TripController>(() => TripController(), fenix: true);
  }
}