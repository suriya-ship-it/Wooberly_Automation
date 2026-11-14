import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_name/utils/contact_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app_name/models/edit_profile_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/controllers/manage_contact_controller.dart';
import 'package:app_name/widgets/manage_contact_card.dart';
import 'package:app_name/widgets/primary_button.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_fonts.dart';
import '../resources/values/app_images.dart';
import '../utils/globals.dart' as globals;

class ManageContact extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<ManageContact> implements ContactSelected {
  final ManageContactController _manageContactController = Get.find();
  EmergencyContacts? emergencyContacts;
  RxBool _loadingController = false.obs;
  late BuildContext buildercontext;

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return PrimaryScaffold(
        appBarTitle: 'emergency_contacts'.tr,
        onChanged: (map) {
          buildercontext = map["scaffoldcontext"];
        },
        body: Obx(() {
          List<EmergencyContacts> list = _manageContactController.selectedContactStrem;
          if (list.length == 0) {
            return _noData();
          }
          int size = list.length;

          return Padding(
              padding: const EdgeInsetsDirectional.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: size,
                      itemBuilder: (context, i) {
                        return Column(
                          children: [
                            ManageContactCard(
                                list.length == 1
                                    ? 3
                                    : i == 0
                                        ? 1
                                        : i == (list.length - 1)
                                            ? 2
                                            : 0,
                                list[i],
                                this,true),
                            size - 1 == i
                                ? Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        top: 30.0),
                                    child: const Divider(
                                      height: 2,
                                    ))
                                : const SizedBox.shrink(),
                            (size - 1 == i && list.length < 5)
                                ? Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        top: 30.0),
                                    child: Text('emergency_contacts_content'.tr,
                                        style: TextStyle(
                                            color: AppColors.BLACK_TEXT_COLOR,
                                            fontSize: AppDimen.text_size_14)),
                                  )
                                : const SizedBox.shrink()
                          ],
                        );
                      },
                      separatorBuilder: (context, index) {
                        return index == size - 1
                            ? const SizedBox.shrink()
                            : const Divider(
                                height: 2,
                              );
                      },
                    ),
                  ),
                  list.length < 5 ? _addButton() : const SizedBox.shrink(),
                ],
              ));
        }),
      );
    });
  }

  Widget _noData() => Container(
        margin: const EdgeInsetsDirectional.only(top: 20),
        padding: const EdgeInsetsDirectional.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text('emergency_contacts_content'.tr,
                  style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_14)),
            ),
            _addButton(),
          ],
        ),
      );

  /// Opens the system Contact Picker.
  /// On Android 17 / API 37 uses a native Method Channel (ACTION_PICK on
  /// Phone.CONTENT_URI) — no READ_CONTACTS permission required.
  Future<void> _pickContact() async {
    const int totalAllowed = 5;
    final List<EmergencyContacts> existingContacts = _manageContactController.selectedContactStrem;
    final int currentCount = existingContacts.length;
    final int remaining = totalAllowed - currentCount;

    if (remaining <= 0) {
      _manageContactController.showInSnackBar('select_contact'.tr);
      return;
    }

    try {
      _manageContactController.selectedContacts.value = List.from(globals.contacts);
     debugPrint("pickcontact: ${ _manageContactController.selectedContacts.value} --- ${globals.contacts}");
      final List<EmergencyContacts> pickedContacts = await pickContacts(maxCount: remaining);
      if (pickedContacts.isEmpty) return;

      final List<EmergencyContacts> contactsToAdd = <EmergencyContacts>[];

      for (final EmergencyContacts picked in pickedContacts) {
        if (picked.phoneNumber ==null || picked.phoneNumber!.isEmpty) {
          continue;
        }

        final bool alreadySelected = existingContacts
            .any((contact) => contact.phoneNumber == picked.phoneNumber);
        final bool alreadyQueued = contactsToAdd
            .any((contact) => contact.phoneNumber == picked.phoneNumber);

        if (alreadySelected || alreadyQueued) {
          continue;
        }

        contactsToAdd.add(
          EmergencyContacts(
            contactName: picked.contactName,
            phoneNumber: picked.phoneNumber,
          ),
        );
      }

      if (contactsToAdd.isEmpty) {
    //    _manageContactController.showInSnackBar('already_selected'.tr);
        return;
      }

      _loadingController(true);
      _manageContactController
          .addContact(contactsToAdd)
          .then((value) {
        _loadingController(false);
        if (value == '') {
          _manageContactController.netOffSnackbar(_pickContact, false);
        } else if (value != 'SUCCESS') {
          _manageContactController.showInSnackBar(value);
        }
      });
    } catch (e) {
      debugPrint('Contact picker error: $e');
    }
  }

  Widget _addButton() => PrimaryButton(
        buttonTitle: 'add_contact'.tr,
        buttonImage: primaryBtnArrow,
        callback: _pickContact,
      );

  void deleteContact(context, EmergencyContacts emergencyContacts) {
    this.emergencyContacts = emergencyContacts;
     _manageContactController.showConfirmationDialog(
        title: 'are_you_sure'.tr + "?",
        content: emergencyContacts.contactName! + 'trusted_contact'.tr,
        confirmButtonText: toBeginningOfSentenceCase(
            'remove'.tr.toLowerCase())!,
        cancelButtonText: toBeginningOfSentenceCase(
            'cancel_label'.tr.toLowerCase()),
        onConfirm: (){
          Get.back();
          _manageContactController.checkInternet(
              remove_Contacts, true);
        }
    );
  }

  @override
  void onSelected(EmergencyContacts emergencyContacts) {
    deleteContact(context, emergencyContacts);
  }

  remove_Contacts() {
    _loadingController(true);
    _loadingController.refresh();
    _manageContactController.removeContact(emergencyContacts).then((message) {
      if (message == "SUCCESS") {
        _loadingController(false);
        _loadingController.refresh();
      } else {
        _loadingController(false);
        _loadingController.refresh();
        _manageContactController.netOffSnackbar(remove_Contacts, false);
      }
    });
  }
}

class ContactSelected {
  void onSelected(EmergencyContacts emergencyContacts) {}
}