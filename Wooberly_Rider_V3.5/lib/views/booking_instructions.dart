import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/utils/globals.dart' as globals;
import '../../controllers/map_main_controller/map_main_controller.dart';import 'package:app_name/widgets/spin_kit/three_bounce.dart';

import '../resources/values/app_images.dart';

class BookingInstructionsViewState extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => BookingInstructionsView();
}

class BookingInstructionsView extends State<BookingInstructionsViewState> {
  late final MapMainController _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MapMainController();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: AppColors.B3_BLACK_COLOR,
            body: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsetsDirectional.only(top: 70),
                  decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                  ),
                  child: SingleChildScrollView(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                            top: 30.0, end: 20, start: 20, bottom: 10),
                        child: showImageAndTitle(context),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 5, end: 20, start: 20),
                        child: Divider(
                          thickness: 1.1,
                          color: AppColors.DIVIDER_COLOR,
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.only(top: 10.0, end: 20, start: 20),
                        child: showDescriptions(context),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                            top: 20, end: 20, start: 20, bottom: 20),
                        child: showCancelProceedBtns(context),
                      )
                    ],
                  )),
                ))));
  }

  Widget showImageAndTitle(BuildContext context) {
    String precautionImage = globals.UPLOAD_URL +
        "/images/staticpage/" +
        (globals.precautionNotifications?["imageName"] != null
            ? globals.precautionNotifications!["imageName"]
            : "");

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 2),
          child: Visibility(
              visible: globals.precautionNotifications?["imageName"] != null
                  ? true
                  : false,
              child: SizedBox(
                height: 78,
                width: 78,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50.0),
                  child: CachedNetworkImage(
                    imageUrl: precautionImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.fill,
                    placeholder: (context, url) => SpinKitThreeBounce(
                      color: AppColors.PRIMARY_DARK_COLOR,
                      size: 22.0,
                    ),
                    errorWidget: (context, url, error) => new Icon(Icons.error),
                  ),
                ),
              )),
        ),
        Flexible(
            child: Padding(
                padding:  EdgeInsetsDirectional.only(start: 20),
                child: Text(
                  globals.precautionNotifications?["title"] != null
                      ? globals.precautionNotifications!["title"]
                      : "",
                  style: TextStyle(
                      fontSize: AppDimen.text_size_18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.BLACK_TEXT_COLOR),
                  textAlign: TextAlign.left,
                ))),
      ],
    );
  }

  Widget showDescriptions(BuildContext context) {
    return HtmlWidget(
      globals.precautionNotifications?["description"] != null
          ? globals.precautionNotifications!["description"]
          : "",
      onTapUrl: (url) async {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        }
        return url != null;
      },
      textStyle: TextStyle(
          color: AppColors.BLACK_TEXT_COLOR,
          fontSize: AppDimen.text_size_14,
          fontWeight: FontWeight.w400),
    );
  }

  Widget showCancelProceedBtns(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
            onTap: () {
              _viewModel.onClickPrecautionButtons(1);
            },
            child: Container(
              width: MediaQuery.of(context).size.width / 2 - 30,
              height: 50,
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_LIGHT_COLOR,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(width: 1, color: AppColors.PRIMARY_DARK_COLOR)),
              child: Center(
                  child: Text(
                'cancel_label'.tr,
                style: TextStyle(
                    color: AppColors.BLACK_TEXT_COLOR,
                    fontSize: AppDimen.text_size_18,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              )),
            )),
        InkWell(
            onTap: () {
              _viewModel.onClickPrecautionButtons(2);
            },
            child: Container(
              width: MediaQuery.of(context).size.width / 2 - 30,
              height: 50,
              decoration: BoxDecoration(
                  color: AppColors.PRIMARY_DARK_COLOR,
                  borderRadius: BorderRadius.circular(3)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Proceed'.tr,
                    style: TextStyle(
                        color: AppColors.WHITE_TEXT_COLOR,
                        fontSize: AppDimen.text_size_18,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  Container(
                    padding: const EdgeInsetsDirectional.only(start: 7, top: 2),
                    child: RotatedBox(
                      quarterTurns: globals.isRTLLang ? 2:0,
                      child:
                        SvgPicture.asset(
                        primaryBtnArrow,
                        colorFilter: ColorFilter.mode(AppColors.PRIMARY_LIGHT_COLOR, BlendMode.srcIn),
                      ),
                    ),
                  )
                ],
              ),
            ))
      ],
    );
  }
}

class BookingInstructionIF {
  void onClickActionsInPrecautionPage(int selectedButtonType) {}
}