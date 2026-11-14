class CountryListModel {
  GetAllCountries? getAllCountries;

  CountryListModel.fromJson(Map<String, dynamic> json) {
    getAllCountries = json['getAllCountries'] != null
        ? new GetAllCountries.fromJson(json['getAllCountries'])
        : null;
  }

}

class GetAllCountries {
  List<CountryResults>? results;
  int? status;
  Null errorMessage;


  GetAllCountries.fromJson(Map<String, dynamic> json) {
    if (json['results'] != null) {
      results = [];
      json['results'].forEach((v) {
        results?.add(new CountryResults.fromJson(v));
      });
    }
    status = json['status'];
    errorMessage = json['errorMessage'];
  }

}

class CountryResults {
  int? id;
  String? countryCode;
  String? countryName;
  bool? isEnable;
  Null status;
  String? dialCode;

  CountryResults.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    countryCode = json['countryCode'];
    countryName = json['countryName'];
    isEnable = json['isEnable'];
    status = json['status'];
    dialCode = json['dialCode'];
  }
}