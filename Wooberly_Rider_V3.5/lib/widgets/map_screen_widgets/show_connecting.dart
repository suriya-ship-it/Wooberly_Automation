import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/databases/app_preferences.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_images.dart';
import 'package:app_name/utils/globals.dart' as globals;
import '../../controllers/base_controller.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';

class ShowConnecting extends StatefulWidget {
  final MapMainController mapMainController=Get.find();

  ShowConnecting({Key? key}) : super(key: key);

  @override
  State<ShowConnecting> createState() => ShowConnectingState();
}

class ShowConnectingState extends State<ShowConnecting> {

@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      widget.mapMainController.connectOffset?.addListener((){
        widget.mapMainController.update(['lottieLoadController']);
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_){
      widget.mapMainController.updateRxValue(widget.mapMainController.connectingCancelController, false);
    });
    return SafeArea(
      child: SlideTransition(
          position: widget.mapMainController.connectOffset!,
          child: Container(
            height: MediaQuery.of(context).size.height,
              color: AppColors.B3_BLACK_COLOR,
              child: GetBuilder<MapMainController>(
                  id:'connectingCancelController',
                  builder: (builder) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      height: builder.connectingCancelController.value == false ? 90.0 : 170.0,
                      decoration: BoxDecoration(
                        color: AppColors.COMMON_BG_COLOR,
                        borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(10.0),
                            topRight: const Radius.circular(10.0)),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              InkWell(
                                onTap: () {
                                  if (builder.connectingCancelController.value == false)
                                    widget.mapMainController.updateRxValue(widget.mapMainController.connectingCancelController, true);
                                  else
                                    widget.mapMainController.updateRxValue(widget.mapMainController.connectingCancelController, false);
                                },
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.all(20.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsetsDirectional.only(start: 40, end: 40, top: 60),
                                          child: Text(
                                            'connect_nearby'.tr,
                                            style: TextStyle(
                                              color: AppColors.BLACK_TEXT_COLOR,
                                              fontSize: AppDimen.text_size_22,
                                              fontWeight: FontWeight.w600
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                height: MediaQuery.of(context).size.width - 100,
                                width: MediaQuery.of(context).size.width - 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(200)
                                  ),
                                  color: AppColors.PRIMARY_LIGHT_COLOR,border: Border.all(
                                    width: 5,
                                    color: AppColors.PRIMARY_LIGHT_COLOR,
                                )
                                ),
                                child: GetBuilder<MapMainController>(
                                  id:'lottieLoadController',
                                  builder: (builder) {
                                    return Visibility(
                                      visible: widget.mapMainController.connectAnimController?.status == AnimationStatus.completed||widget.mapMainController.connectAnimController?.status == AnimationStatus.forward,
                                      child: Center(
                                        child: Image.asset("assets/lottie_connecting_driver.gif",
                                        ),
                                      ),
                                    );
                                  }
                                ),
                              )
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: InkWell(
                              onTap: () {
                                widget.mapMainController.cancelRequestLoadingController(0);
                                widget.mapMainController.checkInternet(
                                    widget.mapMainController.cancelTripRequest,
                                    true);
                                widget.mapMainController.updatePadding(0);
                              },
                              child: Container(
                                height: 50,
                                width: MediaQuery.of(context).size.width,
                                margin: const EdgeInsetsDirectional.only(
                                    bottom: 40.0,
                                    end: 20.0,
                                    start: 20.0,
                                    top: 15.0),
                                padding: const EdgeInsetsDirectional.only(
                                  bottom: 3.0,
                                ),
                                child: Obx((){
                                      if (widget.mapMainController.cancelRequestLoadingController.value == 1)
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                'cancel_request'.tr,
                                                style: TextStyle(
                                                    color: AppColors.PROMOCODE_LINK_COLOR,
                                                    fontSize: AppDimen.text_size_18,
                                                    fontWeight: FontWeight.w500
                                                )),
                                            Transform.rotate(
                                              angle: globals.isRTLLang ? 180 * pi / 180 : 0,
                                              child: Container(
                                                padding:  EdgeInsetsDirectional.only(start:globals.isRTLLang ? 0 : 7,end: globals.isRTLLang  ? 7 : 0),
                                                child: SvgPicture.asset(
                                                  primaryRightArrowSvg,
                                                 colorFilter: ColorFilter.mode(AppColors.PROMOCODE_LINK_COLOR, BlendMode.srcIn),
                                                ),
                                              ),
                                            )
                                          ],
                                        );
                                      else
                                        return Center(
                                          child: SizedBox(
                                            height: 15.0,
                                            width: 15.0,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                              backgroundColor: AppColors
                                                  .PRIMARY_DARK_COLOR,
                                              valueColor:
                                              new AlwaysStoppedAnimation<
                                                  Color>(
                                                  AppColors
                                                      .INDICATOR_COLOR),
                                            ),
                                          ),
                                        );
                                    }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
          )
      ),
    );
  }
}