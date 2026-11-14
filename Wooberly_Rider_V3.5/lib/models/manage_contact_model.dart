import 'package:app_name/models/edit_profile_model.dart';

class ManageContactModel {
  AddEmergencyContact? addEmergencyContact;

  ManageContactModel.fromJson(Map<String, dynamic> json) {
    addEmergencyContact = json['addEmergencyContact'] != null
        ? new AddEmergencyContact.fromJson(json['addEmergencyContact'])
        : null;
  }

}

class AddEmergencyContact {
  String? status;
  String? errorMessage;
  List<EmergencyContacts>? result;
  
  AddEmergencyContact.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    errorMessage = json['errorMessage'];
    if (json['result'] != null) {
      result =[];
      json['result'].forEach((v) {
        result?.add(new EmergencyContacts.fromJson(v));
      });
    }
  }

}