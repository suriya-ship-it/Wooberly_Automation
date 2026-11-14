enum SelectLocationEnum {
  homeLocation,
  workLocation,
  bookingDriverLocation,
}

class SelectLocationModel{
  SelectLocationEnum selectLocationEnum;
  String location;
  double lat;
  double lng;
  bool isValidLocation;
  int? id;
  SelectLocationModel({required this.location,required this.selectLocationEnum,required this.lat,required this.lng,required this.isValidLocation, this.id});
}