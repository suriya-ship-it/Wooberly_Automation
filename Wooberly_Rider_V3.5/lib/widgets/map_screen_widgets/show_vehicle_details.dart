import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:app_name/resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../size_find_widget.dart';

class ShowVehicleDetails extends StatefulWidget {
  final MapMainController mapMainController = Get.find();

  ShowVehicleDetails({Key? key}) : super(key: key);

  @override
  State<ShowVehicleDetails> createState() => ShowVehicleDetailsState();
}

class ShowVehicleDetailsState extends State<ShowVehicleDetails> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlideTransition(
        position: widget.mapMainController.vehicleCatDetailOffset!,
        child: Obx(() {
              return Container(
                color: widget.mapMainController.colorChangeController.value == 1
                        ? AppColors.B3_BLACK_COLOR
                        : Colors.transparent,
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsetsDirectional.symmetric(
                            vertical: 20.0, horizontal: 25.0),
                        decoration: BoxDecoration(
                          color: AppColors.PRIMARY_LIGHT_COLOR,
                        ),
                        child: Obx((){
                              Map<String, dynamic> vehicleCategory = {};
                                  vehicleCategory = widget.mapMainController.vehCatDetailController.value ?? {};

                              ImageProvider? _image;

                              if(vehicleCategory["categoryImg"] != null){
                                _image = MemoryImage(vehicleCategory["categoryImg"]);
                              }else{
                                _image = NetworkImage(globals.UPLOAD_URL + "/images/category/" + (vehicleCategory["categoryImage"] ?? ""));
                              }
                              if ( vehicleCategory.isNotEmpty)
                                return Column(
                                  children: <Widget>[
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            widget.mapMainController.isVehicleCatDetailOpen = false;
                                            widget.mapMainController.destLocAnimController?.forward();
                                            widget.mapMainController.vehicleCatDetailAnimController?.reverse();
                                          },
                                          child: Container(
                                            height: 40,
                                            width: 40,
                                            decoration: BoxDecoration(
                                                color:
                                                    AppColors.COMMON_BG_COLOR,
                                                borderRadius:
                                                   const BorderRadius.all(
                                                        Radius.circular(20))),
                                            child: RotatedBox(
                                              quarterTurns: globals.isRTLLang ? 2:0,
                                              child: SvgPicture.asset(
                                                primaryLeftArrow,
                                                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                                fit: BoxFit.scaleDown,

                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 70,
                                      width: 70,
                                      alignment: Alignment.center,
                                      margin:
                                          const EdgeInsetsDirectional.only(top: 15.0),
                                      decoration: new BoxDecoration(
                                          color:
                                              AppColors.COMMON_BG_COLOR,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50))
                                          ),
                                      child: Container(
                                          decoration: new BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: new DecorationImage(
                                                  fit: BoxFit.scaleDown,
                                                  image: _image,
                                              )
                                          )
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(bottom: 10),
                                      child: Text(
                                        vehicleCategory["categoryName"],
                                        style: TextStyle(
                                            color: AppColors.BLACK_TEXT_COLOR,
                                            fontSize: AppDimen.text_size_18,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                          color: AppColors.COMMON_BG_COLOR,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(10))),
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 15,
                                          end: 15,
                                          top: 10,
                                          bottom: 15),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: <Widget>[
                                              Text(
                                                'capacity'.tr +
                                                    '  ',
                                                style: TextStyle(
                                                    color: AppColors
                                                        .BLACK_TEXT_COLOR,
                                                    fontSize: AppDimen
                                                        .text_size_14),
                                              ),
                                              Expanded(
                                                child: const SizedBox(
                                                  height: 32,
                                                ),
                                              ),
                                              Text(
                                                '${vehicleCategory["capacity"]}',
                                                style: TextStyle(
                                                    color: AppColors
                                                        .BLACK_TEXT_COLOR,
                                                    fontSize:
                                                    AppDimen.text_size_16,
                                                    fontWeight:
                                                    FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: <Widget>[
                                              Text(
                                                'base_fare'.tr +
                                                    "  ",
                                                style: TextStyle(
                                                    color: AppColors
                                                        .BLACK_TEXT_COLOR,
                                                    fontSize: AppDimen
                                                        .text_size_14),
                                              ),
                                              Expanded(
                                                child: const SizedBox(
                                                  height: 32,
                                                ),
                                              ),
                                              RichText(
                                                  text: TextSpan(
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .BLACK_TEXT_COLOR,
                                                          fontSize: AppDimen
                                                              .text_size_16,
                                                          fontWeight:
                                                          FontWeight
                                                              .w500),
                                                      children: [
                                                        TextSpan(
                                                          text: globals
                                                              .currencySymbol,
                                                        ),
                                                        TextSpan(
                                                          text:
                                                          '${vehicleCategory["basePrice"]}',
                                                          style: TextStyle(
                                                              fontFamily:
                                                              AppFont.font,
                                                              fontSize: AppDimen
                                                                  .text_size_16,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w500),
                                                        ),
                                                      ])),
                                            ],
                                          ),
                                          Row(
                                            children: <Widget>[
                                              Text(
                                                '${globals.distanceType == "km" ? 'per_km'.tr : 'per_mile'.tr} ',
                                                style: TextStyle(
                                                    color: AppColors
                                                        .BLACK_TEXT_COLOR,
                                                    fontSize: AppDimen
                                                        .text_size_14),
                                              ),
                                              Expanded(
                                                child: const SizedBox(
                                                  height: 32,
                                                ),
                                              ),
                                              RichText(
                                                  text: TextSpan(
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .BLACK_TEXT_COLOR,
                                                          fontSize: AppDimen
                                                              .text_size_16,
                                                          fontWeight:
                                                          FontWeight
                                                              .w500),
                                                      children: [
                                                        TextSpan(
                                                          text: globals
                                                              .currencySymbol,
                                                        ),
                                                        TextSpan(
                                                          text:
                                                          '${vehicleCategory["unitPrice"]}',
                                                          style: TextStyle(
                                                              fontFamily:
                                                              AppFont.font,
                                                              fontSize: AppDimen
                                                                  .text_size_16,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w500),
                                                        ),
                                                      ])),
                                            ],
                                          ),
                                          Row(
                                            children: <Widget>[
                                              Text(
                                                'per_minute'.tr +
                                                    '  ',
                                                style: TextStyle(
                                                    color: AppColors
                                                        .BLACK_TEXT_COLOR,
                                                    fontSize: AppDimen
                                                        .text_size_14),
                                              ),
                                              Expanded(
                                                child: const SizedBox(
                                                  height: 32,
                                                ),
                                              ),
                                              RichText(
                                                  text: TextSpan(
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .BLACK_TEXT_COLOR,
                                                          fontSize: AppDimen
                                                              .text_size_16,
                                                          fontWeight:
                                                          FontWeight
                                                              .w500),
                                                      children: [
                                                        TextSpan(
                                                          text: globals
                                                              .currencySymbol,
                                                        ),
                                                        TextSpan(
                                                          text:
                                                          '${vehicleCategory["minutePrice"]}',
                                                          style: TextStyle(

                                                              fontFamily:
                                                              AppFont.font,
                                                              fontSize: AppDimen
                                                                  .text_size_16,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w500),
                                                        ),
                                                      ])),
                                            ],
                                          ),
                                          Visibility(
                                            visible:
                                            '${vehicleCategory["waitingFare"]}' !=
                                                '0',
                                            child: Row(
                                              children: <Widget>[
                                                Text(
                                                  "${'Waiting_fare'.tr} (${'per_minute'.tr})" +
                                                      '  ',
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .BLACK_TEXT_COLOR,
                                                      fontSize: AppDimen
                                                          .text_size_14),
                                                ),
                                                Expanded(
                                                  child: const SizedBox(
                                                    height: 32,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Align(
                                                    alignment:
                                                    AlignmentDirectional
                                                        .centerEnd,
                                                    child: RichText(
                                                        text: TextSpan(
                                                            style: TextStyle(
                                                                color: AppColors
                                                                    .BLACK_TEXT_COLOR,
                                                                fontSize: AppDimen
                                                                    .text_size_16,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                            children: [
                                                              TextSpan(
                                                                text: globals
                                                                    .currencySymbol,
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                '${vehicleCategory["waitingFare"]}',
                                                                style: TextStyle(

                                                                    fontFamily:
                                                                    AppFont
                                                                        .font,
                                                                    fontSize: AppDimen
                                                                        .text_size_16,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                              ),
                                                            ])),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                            visible:
                                            '${vehicleCategory["waitingFare"]}' !=
                                                '0',
                                            child: Stack(
                                              children: <Widget>[
                                                Padding(
                                                  padding:
                                                  EdgeInsetsDirectional
                                                      .only(top: 5),
                                                  child: RotatedBox(
                                                    quarterTurns: globals.isRTLLang ? 2:0,
                                                    child:
                                                    SvgPicture.asset(
                                                      waitingClockSvg,
                                                      width: 12,
                                                      height: 12,

                                                    ),
                                                  ),
                                                ),
                                                RichText(
                                                    text: TextSpan(
                                                        style: TextStyle(
                                                            fontFamily:
                                                            AppFont.font,
                                                            color: AppColors
                                                                .BLACK_TEXT_COLOR,
                                                            fontSize: AppDimen
                                                                .text_size_14,
                                                            fontWeight:
                                                            FontWeight
                                                                .w400),
                                                        children: [
                                                          TextSpan(
                                                            text: "    ",
                                                          ),
                                                          TextSpan(
                                                            text:
                                                            'Note'.tr,
                                                          ),
                                                          TextSpan(
                                                            text: " "+'Waiting_fare_desc'.tr,
                                                            style: TextStyle(
                                                                color: AppColors.PLACEHOLDER_TEXT_COLOR,
                                                                fontFamily:
                                                                AppFont.font,
                                                                fontSize: AppDimen
                                                                    .text_size_14,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w400),
                                                          ),
                                                        ])),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              else
                                return const SizedBox.shrink();
                            }),

                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }
}