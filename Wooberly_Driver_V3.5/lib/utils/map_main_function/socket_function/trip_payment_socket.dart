import 'package:get/get.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../../views/map_main_screen.dart';

class TripPaymentSocket {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  TripPaymentSocket({required this.state});

  void TripPayment() {
    String eventName = "tripPayment-" + globals.userid;
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          int paymentType = data["data"]["data"]["paymentType"];
          controller.change(rxVariable: controller.rxPaymentType, value: paymentType);
          controller.totalTripAmount = double.parse(data["data"]["data"]["driverTotalFare"].toString());
          if (data["data"]["data"]["id"].toString() ==
              controller.bookingID.toString()) {
            _updatePayments(data);
          }
        }
      }
    });
  }

  void updateTip() {
    String eventName = "updateTip-" + (controller.bookingID).toString();
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          controller.getTripStatus('rideFinalAmount').then((value) {
            if (value.isEmpty) {
              controller.change(rxVariable: controller.rxFinalAmountController, value: 1.0);
            }
          });
        }
      }
    });
  }

  void changePayment() {
    String eventName = "changePayment-" + (controller.bookingID).toString();
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          controller.getTripStatus('rideFinalAmount').then((value) {
            if (value.isEmpty) {
              controller.change(rxVariable: controller.rxFinalAmountController, value: 1.0);
            }
          });
        }
      }
    });
  }

  void changePaymentDriver() {
    String eventName = "changePaymentDriver-" + (globals.userid).toString();
    globals.socket?.off(eventName);
    globals.socket?.on(eventName, (data) {
      print("===>>>---calling_value_data ${data}");
      if (data is Map) {
        print("===>>>---calling_value_data_2 ${data["data"]}");
        if (data["data"]["status"] == 200) {
          print("===>>>---calling_value_data_3 ${data["data"]["data"]["bookingId"]} === ${controller.bookingID}");
          if(data["data"]["data"]["bookingId"] == controller.bookingID) {
            controller.change(rxVariable: controller.rxPaymentType, value: data["data"]["data"]["paymentType"]);
          }
        }
      }
    });
  }

  void _updatePayments(Map data) {
    controller.getTripStatus('rideFinalAmount').then((value) {
      if (value.isEmpty) {
        if (data["data"]["data"]["id"].toString() ==
            controller.bookingID.toString()) {
          controller.change(rxVariable: controller.rxFinalAmountController, value: 1.0);
        }
      } else {
        _updatePayments(data);
      }
    });
  }
}