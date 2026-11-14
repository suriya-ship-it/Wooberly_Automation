import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/models/select_location_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/payment_container.dart';

import '../../app/app_routes.dart';
import '../../interfaces/change_payment_type.dart';
import '../../resources/values/app_colors.dart';
import '../../resources/values/app_dimen.dart';
import '../../resources/values/app_fonts.dart';
import '../../resources/values/app_images.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';
import '../../services/payment_sheet_service.dart';
import '../../views/map_main_screen.dart';
import '../primary_button.dart';

class ShowConfirmPopup extends StatefulWidget {
  final MapMainController mapMainController = Get.find();
  late final HomeViewState state;

  ShowConfirmPopup({Key? key, required this.state}) : super(key: key);

  @override
  State<ShowConfirmPopup> createState() => ShowConfirmPopupState();
}

class ShowConfirmPopupState extends State<ShowConfirmPopup> implements changePayment_and_Backnav_Interface {
  int _tempPaymentMethod = 0;
  String amount = "0.0";

  @override
  void initState() {
    super.initState();

    globals.changePayment_and_Backnav = this;

    if (globals.cardLastFour != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.mapMainController.update(['paymentController']);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SafeArea(
        child: SlideTransition(
          position: widget.mapMainController.confirmOffset!,
          child: Obx(() {
            debugPrint("totalamount: ${ widget.mapMainController.totalFareController.value}");
            amount = widget.mapMainController.totalFareController.value.toString();

            return Container(
              color: widget.mapMainController.colorChangeController.value == 1
                  ? AppColors.B3_BLACK_COLOR
                  : Colors.transparent,
              alignment: Alignment.bottomCenter,
              child: Wrap(alignment: WrapAlignment.end, children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.PRIMARY_LIGHT_COLOR,
                  ),
                  padding: const EdgeInsetsDirectional.only(top: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          debugPrint("widget.mapMainController.tripFinalAmount: ${widget.mapMainController.tripFinalAmount} --${widget.mapMainController.locationData.length}");
                          if (widget.mapMainController.tripFinalAmount != null) {
                            widget.mapMainController.tripAmountController?.forward();
                            widget.mapMainController.confirmPopupAnimController?.reverse();
                            Future.delayed(const Duration(milliseconds: 700), () {
                              widget.mapMainController.paymentStatusController(0);
                            });
                          } else if (widget.mapMainController.locationData.isEmpty || widget.mapMainController.locationData.length==1) {
                            if (!widget.mapMainController.isScheduleRideIconEnable) {
                              widget.mapMainController.isScheduleRide = false;
                            }
                            widget.mapMainController.confirmPopupAnimController?.reverse();
                            widget.mapMainController.destLocAnimController?.forward();
                            widget.mapMainController.setDestPlaceController("");
                            widget.mapMainController.clearMap();
                            widget.mapMainController.locationData.clear();
                            widget.mapMainController.setCurrentLocation(LatLng(0.0, 0.0));
                              if (widget.mapMainController.isScheduleRideConfirmed) {
                                widget.mapMainController.setLocIconPositionForConfirm();
                              } else {
                                widget.mapMainController.setDefaultLocationIconPosition();
                              }

                          } else {
                            widget.mapMainController.setLocIconPositionForCategory();
                            widget.mapMainController.confirmPopupAnimController?.reverse();
                            widget.mapMainController.destLocAnimController?.forward();
                            widget.mapMainController.vehicleCatAnimController?.forward();
                          }
                        },
                        child: Container(
                          height: 40,
                          width: 40,
                          margin: const EdgeInsetsDirectional.only(top: 10, bottom: 20, end: 24.0, start: 24),
                          decoration: BoxDecoration(
                              color: AppColors.COMMON_BG_COLOR,
                              borderRadius: BorderRadius.all(Radius.circular(20))),
                          child: RotatedBox(
                            quarterTurns: globals.isRTLLang ? 2 : 0,
                            child: SvgPicture.asset(
                              primaryLeftArrow,
                              colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                              fit: BoxFit.scaleDown,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                        child: Text('payment_method'.tr,
                            style: TextStyle(
                                color: AppColors.BLACK_TEXT_COLOR,
                                fontSize: AppDimen.text_size_18,
                                fontWeight: FontWeight.w600)),
                      ),
                      Obx(() {
                        _tempPaymentMethod = globals.selectedPaymentType.value ?? 0;
                        debugPrint("globals.selectedPaymentType.value: ${globals.selectedPaymentType.value}");
                        return Container(
                          height: 350,
                          margin: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                          child: SingleChildScrollView(
                              child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ...?globals.paymentMethods?.map((paymentId) {
                                final _paymentItemMap = widget.mapMainController.paymentItemMap(
                                  paymentOnTap: () async {
                                    if (paymentId == 1 ||
                                        paymentId == 4 ||
                                        paymentId == 5 ||
                                        paymentId == 6) {
                                      if (widget.mapMainController.tripFinalAmount == null) {
                                        updatePaymentMethod(paymentId);
                                      } else {
                                        globals.selectedPaymentType.value = (paymentId);
                                      }
                                    } else if (paymentId == 2) {
                                      if (globals.cardLastFour == 0 ||globals.cardLastFour == null ||
                                              globals.cardLastFour.toString().isEmpty) {
                                        try {
                                          if ( globals.stripePublishableKey.isNotEmpty) {
                                            await PaymentSheetService.start(
                                              context: context,
                                              isFrom: "confirmPopup",
                                            );
                                            if (globals.cardLastFour != 0) {
                                              if (widget.mapMainController.tripFinalAmount == null) {
                                                updatePaymentMethod(2);
                                              } else {
                                                if( globals.selectedPaymentType.value == 2)
                                                  globals.selectedPaymentType.refresh();

                                                globals.selectedPaymentType.value = (2);
                                              }
                                              widget.mapMainController.update(['paymentController']);
                                            }
                                          } else {
                                            widget.mapMainController
                                                .showInSnackBar('stripe_key_empty_error'.tr);
                                          }
                                        } catch (error) {
                                          debugPrint("card error: " + error.toString());
                                        }
                                      } else {
                                        if (widget.mapMainController.tripFinalAmount == null) {
                                          updatePaymentMethod(2);
                                        } else {
                                          globals.selectedPaymentType.value = (2);
                                        }
                                      }
                                    } else if (paymentId == 3) {
                                      if (globals.walletBalance.value < 1) {
                                        globals.checkNavWallet = "updatePaymentToWallet";
                                        Get.toNamed(AppRoutes.APP_WALLET)?.then((value) {
                                          if (widget.mapMainController.tripFinalAmount == null) {
                                            if (globals.preferredPaymentMethod == 3) {
                                              globals.selectedPaymentType.value = (3);
                                            }
                                          } else {
                                            globals.selectedPaymentType.value = (3);
                                          }
                                        });
                                      } else {
                                        if (widget.mapMainController.tripFinalAmount == null) {
                                          updatePaymentMethod(3);
                                        } else {
                                          globals.selectedPaymentType.value = (3);
                                        }
                                      }
                                    }
                                  },
                                );
                                return PaymentContainer(
                                  paymentTitle: _paymentItemMap[paymentId]['paymentName'],
                                  paymentValue: widget.mapMainController.tripFinalAmount == null
                                      ? globals.preferredPaymentMethod
                                      : globals.selectedPaymentType.value,
                                  paymentId: _paymentItemMap[paymentId]['paymentId'],
                                  paymentSvg: _paymentItemMap[paymentId]['paymentSvg'],
                                  bgColor: AppColors.COMMON_BG_COLOR,
                                  svgColorFilter: paymentId == 1 || paymentId == 2 || paymentId == 3
                                      ? ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn)
                                      : null,
                                  callback: _paymentItemMap[paymentId]['paymentOnTap'],
                                );
                              }).toList(),
                              if ((globals.paymentMethods?.contains(2) ?? false) && globals.cardLastFour != 0)
                                GetBuilder<MapMainController>(
                                  id: 'paymentController',
                                  builder: (_) {
                                    return globals.cardLastFour !=0 && globals.cardLastFour !=null
                                        ? Column(
                                            children: <Widget>[
                                              Padding(
                                                padding: const EdgeInsetsDirectional.only(top: 12),
                                                child: Text(
                                                  'agree_payment_type'.trParams({"field": globals.APP_NAME}),
                                                  style: TextStyle(
                                                    color: AppColors.BLACK_TEXT_COLOR,
                                                    fontFamily: AppFont.font,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: AppDimen.text_size_14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsetsDirectional.only(start: 20, end: 10),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: AppColors.BORDERCOLOR),
                                                  borderRadius: BorderRadius.all(Radius.circular(3)),
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                   globals.selectedPaymentType.value= 2;
                                                  },
                                                  child: Container(
                                                    height: 50,
                                                    child: Row(
                                                      children: <Widget>[
                                                        SvgPicture.asset(
                                                          creditCardSvg,
                                                          height: 13,
                                                          width: 20,
                                                          colorFilter: ColorFilter.mode(
                                                              AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                                        ),
                                                        const SizedBox(width: 10.0),
                                                        Expanded(
                                                          child: Text(
                                                            "**** **** **** ${globals.cardLastFour}",
                                                            style: TextStyle(
                                                              color: AppColors.BLACK_TEXT_COLOR,
                                                              fontFamily: AppFont.font,
                                                              fontSize: AppDimen.text_size_14,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                        InkWell(
                                                          onTap: () async {
                                                            try {
                                                              if (globals.stripePublishableKey != null &&
                                                                  globals.stripePublishableKey.isNotEmpty) {
                                                                await PaymentSheetService.start(
                                                                  context: context,
                                                                  isFrom: "updateCard",
                                                                );
                                                                globals.selectedPaymentType.refresh();
                                                              } else {
                                                                widget.mapMainController.showInSnackBar(
                                                                    "Stripe key must not be empty. Please contact support!!");
                                                              }
                                                            } catch (error) {
                                                              debugPrint("card error: " + error.toString());
                                                            }
                                                          },
                                                          child: SvgPicture.asset(
                                                            editingSvg,
                                                            colorFilter: ColorFilter.mode(
                                                                AppColors.PROMOCODE_LINK_COLOR,
                                                                BlendMode.srcIn),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 20),
                                                        InkWell(
                                                          onTap: () {
                                                            _asyncConfirmDialog(context);
                                                          },
                                                          child: SvgPicture.asset(
                                                            deleteSVG,
                                                            colorFilter: ColorFilter.mode(
                                                                AppColors.PROMOCODE_LINK_COLOR,
                                                                BlendMode.srcIn),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink();
                                  },
                                ),
                            ],
                          )),
                        );
                      }),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 24),
                        decoration: BoxDecoration(color: AppColors.PRIMARY_LIGHT_COLOR, boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10.0,
                            spreadRadius: 5.1,
                          )
                        ]),
                        child: Column(
                          children: [
                            Opacity(
                              opacity: 1.0,
                              child: Padding(
                                  padding: const EdgeInsetsDirectional.symmetric(vertical: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            margin: const EdgeInsetsDirectional.only(top: 2, end: 10),
                                            child: SvgPicture.asset(
                                              updatedVerified,
                                              height: 22,
                                              width: 22,
                                              colorFilter: ColorFilter.mode(
                                                  AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                            ),
                                          ),
                                          Text(
                                            "${widget.mapMainController.tripFinalAmount == null ? 'estimated_amount'.tr : 'total_trip_amount'.tr} ",
                                            style: TextStyle(
                                                color: AppColors.BLACK_TEXT_COLOR,
                                                fontSize: AppDimen.text_size_16,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: AppFont.font),
                                          ),
                                        ],
                                      ),
                                      RichText(
                                          text: TextSpan(
                                              style: TextStyle(
                                                color: AppColors.BLACK_TEXT_COLOR,
                                                fontSize: AppDimen.text_size_18,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              children: [
                                            TextSpan(
                                                text: globals.currencySymbol,
                                                style: TextStyle(
                                                  color: AppColors.BLACK_TEXT_COLOR,
                                                  fontSize: AppDimen.text_size_18,
                                                  fontWeight: FontWeight.w500,
                                                )),
                                            TextSpan(
                                                text: double.parse(amount).toStringAsFixed(2),
                                                style: TextStyle(
                                                    color: AppColors.BLACK_TEXT_COLOR,
                                                    fontSize: AppDimen.text_size_18,
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: AppFont.font))
                                          ])),
                                    ],
                                  )),
                            ),
                            PrimaryButton(
                              buttonTitle: 'confirm_label'.tr,
                              buttonImage: primaryRightArrowSvg,
                              callback: () {
                                _confirmPayment();
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            );
          }),
        ),
      ),
    );
  }

  _confirmPayment() {
    if (globals.paymentMethods?.contains(globals.preferredPaymentMethod) ?? false) {
      if ((globals.cardLastFour == 0 ||globals.cardLastFour ==null)  && globals.selectedPaymentType.value == 2) {
        widget.mapMainController.showInSnackBar('please_enter_correct_card_details'.tr);
      } else if (globals.selectedPaymentType.value == 3 && double.parse(amount) > globals.walletBalance.value) {
        widget.mapMainController.showInSnackBar('wallet_not_enough'.tr);
      } else {
        if (widget.mapMainController.tripFinalAmount != null &&   widget.mapMainController.tripStatusResult !=null && widget.mapMainController.tripStatusResult["result"]["paymentStatus"] != 'completed') {
        widget.mapMainController.checkInternet(() {
            widget.mapMainController
                .updatepaymentMethod(_tempPaymentMethod)
                .then((value) {
              if (value.isNotEmpty) {
                widget.mapMainController.showInSnackBar(value);
              } else {
                debugPrint("_tempPaymentMethod: ${_tempPaymentMethod}");
                globals.selectedPaymentType.value = _tempPaymentMethod;
                widget.mapMainController.changePaymentTypePayment().then((value) {
                  widget.mapMainController.tripAmountController?.forward();
                    widget.mapMainController.confirmPopupAnimController?.reverse();
                  debugPrint("globals.preferredPaymentMethod123: ${globals.preferredPaymentMethod}");
                    if (globals.preferredPaymentMethod != 1) {
                      widget.mapMainController.finalAmountController(1.0);
                    }
                  widget.mapMainController.checkInternet(updateTips, true);
                    widget.mapMainController.rideCurrency = globals.preferredPaymentMethod;
                    widget.mapMainController.paymentStatusController(0);

                });
              }
            });
          }, true);
        } else {
          widget.mapMainController.checkInternet(widget.mapMainController.confirmRide, true);
        }

      }
    } else {
      widget.mapMainController.showInSnackBar('payment_method_error'.tr);
    }
  }

  Future<void> _asyncConfirmDialog(BuildContext context) async {
    widget.mapMainController.showConfirmationDialog(
        title: 'delete_card'.tr,
        content: 'are_you_sure'.tr + " " + 'delete_card_content'.tr + "?",
        cancelButtonText: 'cancel_label'.tr,
        onConfirm: (){
          widget.mapMainController.checkInternet(removeCard, false);
          Get.back();
        },
        onCancel: (){
          Get.back();
          widget.mapMainController.setPaymentType(true);
        },
        confirmButtonText: 'delete'.tr);
  }

  updatePaymentMethod(int value) {
    widget.mapMainController.checkInternet(() {
      widget.mapMainController.updatepaymentMethod(value).then((value) {
        if (value.isNotEmpty) {
          widget.mapMainController.showInSnackBar(value);
        }
      });
    }, true);
  }

  removeCard() {
    widget.mapMainController.removeCardDetails().then((value) {
      if (value.isNotEmpty) {
        widget.mapMainController.showInSnackBar(value);
      } else {
        Updatepayment();
        globals.cardLastFour = 0;
        globals.preferredPaymentMethod = globals.paymentMethods?.firstOrNull ?? 0;
      }
    });
  }

  Updatepayment() {
    widget.mapMainController.setPaymentType(false);
    globals.cardLastFour = 0;

    widget.mapMainController.checkInternet(updatePaymentMethod, false);
  }

  @override
  void changePayment_and_Backnav() {
    widget.mapMainController.setBackNavigation();
  }

  updateTips() {
    widget.mapMainController.tipsAmount.text = "";
    widget.mapMainController.updateTips().then((value) {
      if (value.isNotEmpty) {
        widget.mapMainController.showInSnackBar(value);
      } else {
        widget.mapMainController.getRideStatus().then((value) {});
      }
    });
  }
}