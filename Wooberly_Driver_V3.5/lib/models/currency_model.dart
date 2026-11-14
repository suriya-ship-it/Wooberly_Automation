class CurrencyModel {
  GetAllCurrencies? getAllCurrencies;

  CurrencyModel.fromJson(Map<String, dynamic> json) {
    getAllCurrencies = json['getAllCurrencies'] != null
        ? new GetAllCurrencies.fromJson(json['getAllCurrencies'])
        : null;
  }
}

class GetAllCurrencies {
  List<CurrencyResults>? results;
  String? status;
  String? errorMessage;


  GetAllCurrencies.fromJson(Map<String, dynamic> json) {
    if (json['results'] != null) {
      results = [];
      json['results'].forEach((v) {
        results?.add(new CurrencyResults.fromJson(v));
      });
    }
    status = json['status'];
    errorMessage = json['errorMessage'];
  }

}

class CurrencyResults {
  int? id;
  String? symbol;
  bool? isEnable;
  bool? isPayment;
  bool? isBaseCurrency;


  CurrencyResults.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    symbol = json['symbol'];
    isEnable = json['isEnable'];
    isPayment = json['isPayment'];
    isBaseCurrency = json['isBaseCurrency'];
  }

}