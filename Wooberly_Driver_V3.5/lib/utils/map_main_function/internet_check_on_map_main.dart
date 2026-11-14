import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../../views/map_main_screen.dart';

class InternetCheckOnMapMainScreen {
  final HomeViewState state;
  final MapMainController controller = Get.find();

  InternetCheckOnMapMainScreen({required this.state});

  checkInternetTrackLoc(String func) {
    if (func == "tracklocation" || func == "initiallocation") {
      return ;
    } else
    if (func == "acceptbtnclick") {
      controller.mapsImplementation.init(controller.mapController?.mapId ?? 0);
      globals.isShowMapPage = true;
      controller.updateMapPaddingController(state.bottomSheetHeight);
      Future.delayed(Duration(milliseconds: 100)).then((_) {
        controller.checkInternet(state.rideAcceptSocket!.acceptRide, true);
      });

    } else if (func == "declinebtnclick") {
      controller.mapsImplementation.init(controller.mapController?.mapId ?? 0);
      controller.updateMapPaddingController(state.bottomSheetHeight);
      Future.delayed(Duration(milliseconds: 100)).then((_) {
        controller.checkInternet(state.rideDeclineSocket!.declineRide, true);
      });
       state.backgroundTimer?.cancel();
    }
    else if (func == "startrideclick") {
      controller.mapsImplementation.init(controller.mapController?.mapId ?? 0);
      globals.isShowMapPage = true;
      state.locationFetchOnMapMainScreen?.listenForPermissionStatus(Permission.location, "start");
    } else if (func == "endrideclick") {
      globals.isShowMapPage = true;
      controller.mapsImplementation.init(controller.mapController?.mapId ?? 0);
      state.locationFetchOnMapMainScreen?.listenForPermissionStatus(Permission.location, "end");
    } else if (func == "canceltripclick") {
      print("Cancel Booking::}");
      globals.isShowMapPage = true;
      controller.mapsImplementation.init(controller.mapController?.mapId ?? 0);
      controller.checkInternet(state.driverCancelSocket!.cancelRide, true);
    } else if (func == "goonlineclick") {
      globals.isShowMapPage = true;
      state.locationFetchOnMapMainScreen?.listenForPermissionStatus(Permission.location, "goonline");
    } else if (func == "goofflineclick") {
      controller.setLoadingController(true);
      globals.isShowMapPage = true;
      controller.checkInternet(state.graphQLFetchOnMapMainScreen!.goOffline, true);
    } else if (func == "confirmStop") {
      controller.mapsImplementation.init(controller.mapController?.mapId ?? 0);
      state.locationFetchOnMapMainScreen?.listenForPermissionStatus(Permission.location, "confirmStop");
    } else if (func == "locationReached"){
      controller.mapsImplementation.init(controller.mapController?.mapId ?? 0);
      state.locationFetchOnMapMainScreen?.listenForPermissionStatus(Permission.location, "locationReached");
    }
  }
}