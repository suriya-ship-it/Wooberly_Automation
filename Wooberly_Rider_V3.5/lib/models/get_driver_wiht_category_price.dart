class getDriversWithCategoryAndPrice {
  int id;
  double? lat;
  double? lng;
  String? categoryName;
  String? categoryMarkerImage;
  String? categoryImage;
  int? capacity;
  bool? isActive;
  String? convertCurrency;
  double? totalFareForRider;
  double? basePrice;
  double? minutePrice;
  double? unitPrice;
  double? waitingFare;
  String? driverReachDuration;
  double? specialTripTotalFare;
  double? riderServiceFee;
  double? driverServiceFee;
  double? priceForDistance;
  double? totalFare;

  getDriversWithCategoryAndPrice({
    required this.id,
    this.lat,
    this.lng,
    this.categoryName,
    this.categoryMarkerImage,
    this.categoryImage,
    this.capacity,
    this.isActive,
    this.convertCurrency,
    this.totalFareForRider,
    this.basePrice,
    this.minutePrice,
    this.unitPrice,
    this.waitingFare,
    this.driverReachDuration,
    this.specialTripTotalFare,
    this.riderServiceFee,
    this.driverServiceFee,
    this.priceForDistance,
    this.totalFare
  });


  copyWith({
    required int id,
    double? lat,
    double? lng,
    String? categoryName,
    String? categoryMarkerImage,
    String? categoryImage,
    int? capacity,
    bool? isActive,
    String? convertCurrency,
    double? totalFareForRider,
    double? basePrice,
    double? minutePrice,
    double? unitPrice,
    double? waitingFare,
    String? driverReachDuration,
    double? specialTripTotalFare,
    double? riderServiceFee,
    double? driverServiceFee,
    double? priceForDistance,
    double? totalFare
  }){
    return getDriversWithCategoryAndPrice(
        id: this.id,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        categoryName: categoryName ?? this.categoryName,
        categoryMarkerImage: categoryMarkerImage ?? this.categoryMarkerImage,
        categoryImage: categoryImage ?? this.categoryImage,
        capacity: capacity ?? this.capacity,
        isActive: isActive ?? this.isActive,
        convertCurrency: convertCurrency ?? this.convertCurrency,
        totalFareForRider: totalFareForRider ?? this.totalFareForRider,
        basePrice: basePrice ?? this.basePrice,
        minutePrice: minutePrice ?? this.minutePrice,
        unitPrice: unitPrice ?? this.unitPrice,
        waitingFare: waitingFare ?? this.waitingFare,
        driverReachDuration: driverReachDuration ?? this.driverReachDuration,
        specialTripTotalFare: specialTripTotalFare ?? this.specialTripTotalFare,
        riderServiceFee: riderServiceFee ?? this.riderServiceFee,
        driverServiceFee: driverServiceFee ?? this.driverServiceFee,
        priceForDistance: priceForDistance ?? this.priceForDistance,
        totalFare: totalFare ?? this.totalFare
    );
  }
}