import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:url_launcher/url_launcher.dart';

import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/navigation_item.dart';

import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../resources/values/app_lang.dart';
import '../widgets/primary_scaffold.dart';

class HelpInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpInfoState();
  }
}

class HelpInfoState extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HelpInfoStateView();
}

class HelpInfoStateView extends State<HelpInfoState> {
  bool btnDisableController = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      disableAppbar: false,
      appBarTitle: support_label.tr,
      body: Column(
        children: <Widget>[
          const SizedBox(
            height: 25.0,
          ),
          (globals.supportEmail != null && globals.supportEmail.isNotEmpty)
              ? NavigationItem(
                  iconWidget: mailSvg,
                  navigationName: email_label.tr,
                  navigationValue: globals.supportEmail,
                  isShowdivider: (globals.supportPhone != null &&
                      globals.supportPhone.isNotEmpty),
                  onTap: () {
                    UrlLauncher.launchUrl(
                        Uri.parse("mailto:${globals.supportEmail}"));
                  },
                )
              : const SizedBox(
                  height: 0.0,
                ),
          (globals.supportPhone != null && globals.supportPhone.isNotEmpty)
              ? NavigationItem(
                  iconWidget: callIconSvg,
                  navigationName: btn_contact.tr,
                  navigationValue: globals.supportPhone,
                  isShowdivider: (globals.supportSkype != null &&
                      globals.supportSkype.isNotEmpty),
                  onTap: () {
                    if (!btnDisableController) {
                      btnDisableController = true;
                      String telphone = "tel://${globals.supportPhone}";
                      UrlLauncher.launchUrl(Uri.parse("${telphone}"));
                      Future.delayed(const Duration(seconds: 2), () {
                        btnDisableController = false;
                      });
                    }
                  },
                )
              : const SizedBox.shrink(),
          (globals.supportWhatsapp != null && globals.supportWhatsapp.isNotEmpty)
              ? NavigationItem(
            iconWidget: whatsappSvg,
            navigationName: "WhatsApp",
            isShowdivider: false,
            navigationValue: globals.supportWhatsapp,
            onTap: () {
              String whatsappnumber =  globals.supportWhatsapp
                  .replaceAll(RegExp(r'[^0-9]'), '');
              String message = "";
              String whatsappUrl = "whatsapp://send?phone=${whatsappnumber}&text=${message}";
              if(Platform.isIOS)
                whatsappUrl = "https://wa.me/${whatsappnumber}?text=${Uri.parse(message)}";
              String webUrl = 'https://api.whatsapp.com/send/?phone=${whatsappnumber}&text=${message}';
              UrlLauncher.canLaunchUrl(Uri.parse(whatsappUrl)).then((value) {
                if (value)
                  UrlLauncher.launchUrl(Uri.parse("${whatsappUrl}"),
                      mode: LaunchMode.externalApplication);
                else
                  UrlLauncher.launchUrl(
                      Uri.parse(webUrl),
                      mode: LaunchMode.externalApplication);
              });
            },
          )
              : SizedBox(
            height: 0.0,
          ),
        ],
      ),
    );
  }
}