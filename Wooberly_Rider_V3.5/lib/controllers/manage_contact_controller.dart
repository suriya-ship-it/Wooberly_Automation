import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/models/edit_profile_model.dart';
import 'package:app_name/models/manage_contact_model.dart';
import 'package:app_name/utils/contact_picker.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/base_controller.dart';

class ManageContactController extends BaseController{
  RxList<EmergencyContacts> selectedContactStrem = globals.contacts.obs;
  RxInt allContactsLoadingController =0.obs;
  int maxCount = 5;

  RxList<EmergencyContacts> selectedContacts = <EmergencyContacts>[].obs;
  RxBool isPicking = false.obs;

  int get remainingCount => maxCount - selectedContacts.length;

  Future<void> pickAnotherContact() async {
    if (remainingCount <= 0 || isPicking.value) return;

    isPicking.value = true;

    try {
      final EmergencyContacts? picked = await pickSingleNativeContact();
      if (picked == null) return;

      final alreadyAdded =
      selectedContacts.any((c) => c.phoneNumber == picked.phoneNumber);

      if (alreadyAdded) {
            showInSnackBar('already_selected'.tr);
        return;
      }

      if (selectedContacts.length >= maxCount) return;

      selectedContacts.add(picked);
      debugPrint('globals.contact: 2 ${globals.contacts}');
    } finally {
      isPicking.value = false;
    }
  }

  void removeContactOnList(EmergencyContacts emergencyContacts) {
    selectedContacts.remove(emergencyContacts);
  }

  Future<String> addContact(List<EmergencyContacts> selectedContact) async {
    var variables = <String, dynamic>{"data": selectedContact.toString()};
    Map<String, dynamic>? _contactAdded = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "addContact_mutation",
        variables);
    debugPrint("addContact: ${variables}");
    if (_contactAdded?["addEmergencyContact"]["status"] == "200") {
      ManageContactModel contact = ManageContactModel.fromJson(_contactAdded!);
      var emergencyModelContact = contact.addEmergencyContact;

      globals.contacts.clear();
      globals.contacts.addAll(emergencyModelContact!.result!);
      selectedContactStrem.value = globals.contacts;
      selectedContactStrem.refresh();
      return "SUCCESS";
    } else {
      return _contactAdded?["addEmergencyContact"]["errorMessage"].toString() ?? "";
    }
  }

  Future<String> removeContact(emergencyContacts) async {
    var variables = <String, dynamic>{"contactId": emergencyContacts.id};
    Map<String, dynamic>? deleteContact = await graphQlObject.getMutationValues(
        graphQlObject.graphQLClientWithHeader,
        "deleteContact_mutation",
        variables);
    if (deleteContact?["deleteEmergencyContact"]["status"] == "200") {
      globals.contacts.remove(emergencyContacts);
      selectedContactStrem.value=globals.contacts;
      selectedContactStrem.refresh();
      return "SUCCESS";
    } else {
      return deleteContact?["deleteEmergencyContact"]["errorMessage"] ?? " ";
    }
  }
}