import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/model_theme.dart';
import 'package:app_name/controllers/manage_contact_controller.dart';
import 'package:app_name/models/edit_profile_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/contact_picker.dart';
import 'package:app_name/views/manage_contact.dart';
import 'package:app_name/widgets/manage_contact_card.dart';
import 'package:app_name/widgets/primary_button.dart';
import 'package:app_name/widgets/primary_scaffold.dart';
import '../utils/globals.dart' as globals;
class MultiContactPickerPage extends StatelessWidget implements ContactSelected  {
  final int maxCount;

   MultiContactPickerPage({super.key, required this.maxCount});
  final ManageContactController controller = Get.find();
  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return PrimaryScaffold(
          appBarTitle: 'contacts'.tr,
          body: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 20),
            child: Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${'add_contact'.tr} (${controller.selectedContacts.length}/${controller.maxCount})',
                    style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'label_system_contact_pick'.tr,
                    style: TextStyle(
                      color: AppColors.BLACK_TEXT_COLOR,
                      fontSize: AppDimen.text_size_14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// LIST
                  Expanded(
                    child: controller.selectedContacts.isEmpty
                        ? Center(
                      child: Text(
                        'no_contact'.tr,
                        style: TextStyle(
                          color: AppColors.BLACK_TEXT_COLOR,
                          fontSize: AppDimen.text_size_14,
                        ),
                      ),
                    )
                        : ListView.separated(
                      itemCount: controller.selectedContacts.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final contact = controller.selectedContacts[index];
                        debugPrint("contactselected: ${contact.toString()} -- ${globals.contacts}");
                        return  ManageContactCard(
                            controller.selectedContacts.length == 1
                                ? 3
                                : index == 0
                                ? 1
                                : index == (controller.selectedContacts.length - 1)
                                ? 2
                                : 0,
                            controller.selectedContacts[index],
                            this, !globals.contacts.contains(contact));

                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// ADD BUTTON
                  controller.remainingCount > 0 ?
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(
                        color: AppColors.PRIMARY_DARK_COLOR,
                        width: 1.5,
                      ),
                    ),
                    onPressed: controller.remainingCount <= 0 ||
                        controller.isPicking.value
                        ? null
                        : controller.pickAnotherContact,
                    icon:  Icon(Icons.person_add_alt_1, color:AppColors.BLACK_TEXT_COLOR,),
                    label: Text(
                           'add_contact'.tr,
                      style: TextStyle(
                        color: AppColors.BLACK_TEXT_COLOR,
                      ),
                    ),
                  ) :  const SizedBox.shrink(),

                  const SizedBox(height: 12),

                  /// SUBMIT BUTTON
                  if (controller.selectedContacts.isNotEmpty)
                    PrimaryButton(
                      buttonTitle: controller.selectedContacts.length == 1
                          ? 'add_contact'.tr
                          : '${'btn_label_add_contact_continue'.tr} (${controller.selectedContacts.length})',
                      buttonImage: primaryBtnArrow,
                      callback: () => Get.back(
                        result: controller.selectedContacts.toList(),
                      ),
                    ),
                ],
              );
            }),
          ),
        );
      }
    );
  }

  @override
  void onSelected(EmergencyContacts emergencyContacts) {
    controller.removeContactOnList(emergencyContacts);
  }
}