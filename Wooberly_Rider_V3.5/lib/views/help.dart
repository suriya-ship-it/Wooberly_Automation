import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_name/app/model_theme.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/navigation_item.dart';
import 'package:app_name/widgets/primary_scaffold.dart';

import '../resources/values/app_images.dart';

class Support extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SupportInfoState();
  }
}

class SupportInfoState extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SupportInfoStateView();
}

class SupportInfoStateView extends State<SupportInfoState> {
  bool btnDisableController = false;



  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
        return PrimaryScaffold(
          disableAppbar: false,
          appBarTitle: 'support_label'.tr,
          body: Column(
            children: <Widget>[
              const SizedBox(
                height: 25.0,
              ),
              (globals.supportEmail != null && globals.supportEmail.isNotEmpty)
                  ? NavigationItem(
                      iconWidget: mailSvg,
                      navigationName: 'Email'.tr,
                      navigationValue: globals.supportEmail,
                      isShowdivider: (globals.supportPhone != null &&
                          globals.supportPhone.isNotEmpty),
                      onTap: () {
                          if (!btnDisableController) {
                            btnDisableController = true;
                            UrlLauncher.launchUrl(
                                Uri.parse("mailto:${globals.supportEmail}"));
                            Future.delayed(const Duration(seconds: 2), () {
                              btnDisableController = false;
                            });
                          }
                      },
                    )
                  : const SizedBox.shrink(),
              (globals.supportPhone != null && globals.supportPhone.isNotEmpty)
                  ? NavigationItem(
                      iconWidget: callIconSvg,
                      navigationName: 'btn_contact'.tr,
                      navigationValue: globals.supportPhone,
                      isShowdivider: (globals.supportWhatsapp != null &&
                          globals.supportWhatsapp.isNotEmpty),
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
                  : const SizedBox.shrink(),
            ],
          ),
        );
      }
    );
  }
}