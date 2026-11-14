part of 'map_main_controller.dart';

extension MapKeyUsesOnController on MapMainController {
  Future<String> getUserCurrentLocName() async {
    Future.delayed(const Duration(milliseconds: 14000), () {
      if (globals.rideCompletedAt.latitude == 0.0 ||
          globals.rideCompletedAt.longitude == 0.0) {
        return "failed";
      }
    });

    if (globals.rideCompletedAt.latitude == 0.0 ||
        globals.rideCompletedAt.longitude == 0.0) {
       await App().getNativeLocation();
      globals.rideCompletedAt = LatLng(globals.userLat, globals.userLon);
    }

    List<Placemark>? placemarks = await geocoding.Geocoding().placemarkFromCoordinates(
        globals.rideCompletedAt.latitude, globals.rideCompletedAt.longitude,);

    String street = placemarks[0].street ?? "";
    String country = placemarks[0].country ?? "";
    String thoroughfare = placemarks[0].thoroughfare ?? "";
    String postalCode = placemarks[0].postalCode ?? "";
    String administrativeArea = placemarks[0].administrativeArea ?? "";
    String subAdministrativeArea = placemarks[0].subAdministrativeArea ?? "";
    String locality = placemarks[0].locality ?? "";

    var first = "";
    if (street.isNotEmpty) first = "${street}";
    if (thoroughfare.isNotEmpty && thoroughfare != street) //
      first = "${first}, ${thoroughfare}"; //
    if (locality.isNotEmpty) first = "${first}, ${locality}";
    if (subAdministrativeArea.isNotEmpty)
      first = "${first}, ${subAdministrativeArea}";
    if (administrativeArea.isNotEmpty)
      first = "${first}, ${administrativeArea}";
    if (country.isNotEmpty) first = "${first}, ${country}";
    if (postalCode.isNotEmpty) first = "${first}-${postalCode}";
    rideEndLoc = first;
    return "";
  }
}