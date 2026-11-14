import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_name/models/edit_profile_model.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/views/manage_contact.dart';

class ManageContactCard extends StatelessWidget {
  final EmergencyContacts contact;
  final ContactSelected contactSelected;
  final int index;
  final bool isTrailingVisible;

  ManageContactCard(this.index, this.contact, this.contactSelected,this.isTrailingVisible);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: AppColors.PRIMARY_LIGHT_COLOR,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(index == 1 || index == 3 ? 16.0 : 0),
              topRight: Radius.circular(index == 1 || index == 3 ? 16.0 : 0),
              bottomLeft: Radius.circular(index == 2 || index == 3 ? 16.0 : 0),
              bottomRight: Radius.circular(index == 2 || index == 3 ? 16.0 : 0),
            )),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 7),
        child: ListTile(
          dense: true,
          contentPadding:  EdgeInsetsDirectional.zero,
          leading: CircleAvatar(
              radius: 20.0,
              backgroundColor: AppColors.COMMON_BG_COLOR,
              child: Text(
                contact.contactName![0],
                style: TextStyle(
                    fontSize: AppDimen.text_size_18,
                    color: AppColors.BLACK_TEXT_COLOR,
                    fontWeight: FontWeight.w600),
              )),
          title: Text(
            contact.contactName!,
            style: TextStyle(
                fontSize: AppDimen.text_size_16,
                color: AppColors.BLACK_TEXT_COLOR,
                fontWeight: FontWeight.w600),
          ),
          subtitle: Text(contact.phoneNumber!,
              style: TextStyle(
                  fontSize: AppDimen.text_size_14,
                  color: AppColors.BLACK_TEXT_COLOR)),
          trailing: isTrailingVisible ?
          InkWell(
            onTap: () {
              contactSelected.onSelected(contact);
            },
            child: Container(
              width: 50,
              height: 50,
              child: SvgPicture.asset(
                closeCircleIcon,
                width: 24,
                height: 24,
                fit: BoxFit.scaleDown,
                colorFilter:
                    ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
              ),
            ),
          ): null,
        ));
  }
}