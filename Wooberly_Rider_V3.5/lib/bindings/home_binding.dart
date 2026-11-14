import 'package:get/get.dart';
import 'package:app_name/controllers/add_card_controller.dart';
import 'package:app_name/controllers/edit_account_controller.dart';
import 'package:app_name/controllers/map_main_controller/map_main_controller.dart';
import 'package:app_name/controllers/register_controller.dart';
import 'package:app_name/controllers/trip_controller.dart';

import '../controllers/manage_contact_controller.dart';
import '../controllers/static_page_controller.dart';

class HomeBinding extends Bindings{
  static final HomeBinding _instance=HomeBinding._();

  HomeBinding._();
  factory HomeBinding(){
    return _instance;
  }
  @override
  void dependencies(){
    Get.put(MapMainController(),permanent: true);
    Get.lazyPut(()=>TripController(),fenix: true);
    Get.lazyPut(()=>AddCardController(),fenix: true);
    Get.lazyPut(()=>ManageContactController(),fenix: true);
    Get.lazyPut(()=>StaticPageController(),fenix: true);
    Get.lazyPut(()=>RegisterController(),fenix: true);
  }
}