class GetCancelReasonModel {
  GetCancelReason? getCancelReason;


  GetCancelReasonModel.fromJson(Map<String, dynamic> json) {
    getCancelReason = json['getCancelReason'] != null
        ? new GetCancelReason.fromJson(json['getCancelReason'])
        : null;
  }

}

class GetCancelReason {
  int? status;
  String? errorMessage;
  List<Result>? result;


  GetCancelReason.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    errorMessage = json['errorMessage'];
    if (json['result'] != null) {
      result = [];
      json['result'].forEach((v) {
        result?.add(new Result.fromJson(v));
      });
    }
  }
}

class Result {
  String? id;
  String? reason;
  int? userType;
  bool? isActive;

  Result.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    reason = json['reason'];
    userType = json['userType'];
    isActive = json['isActive'];
  }

}