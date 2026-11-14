import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;

import '../resources/values/app_images.dart';

class ScheduleRide extends StatefulWidget {
  String pickUpPlace;
  String dropOffPlace;
  ScheduleRideControllerIF scheduleRideControllerIF;
  DateTime? dateTime;
  bool isEdit;
  bool isScheduleRideIconEnable;

  ScheduleRide(this.pickUpPlace, this.dropOffPlace, this.scheduleRideControllerIF, this.dateTime, this.isEdit,
      this.isScheduleRideIconEnable);

  @override
  State<StatefulWidget> createState() {
    return ScheduleRideState();
  }
}

class ScheduleRideState extends State<ScheduleRide> {
  final selectedDateTime = DateTime.now().obs;

  @override
  void initState() {
    if(widget.dateTime !=null)
    selectedDateTime.value = widget.dateTime!;
    else {

      DateTime dateTime = DateTime.now();
      selectedDateTime.value = DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour,
          dateTime.minute +  globals.scheduleRestrictionTime + 1);
    }
    debugPrint("ScheduleRideState initState: ${widget.dateTime}");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        bottom: false,
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: InkWell(
              onTap: () => widget.scheduleRideControllerIF
                  .scheduleRideController("cancel screen", selectedDateTime.value),
              child: ColoredBox(
                color: AppColors.B3_BLACK_COLOR,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Obx(() {
                    return ColoredBox(
                      color: AppColors.PRIMARY_LIGHT_COLOR,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 30.0, end: 20.0, start: 20.0, bottom: 10.0),
                            child: Text(
                              'Schedule_a_Ride'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontFamily: AppFont.font,
                                  fontSize: AppDimen.text_size_22,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 5.0, end: 20.0, start: 20.0, bottom: 10.0),
                            child: Text(
                              "${DateFormat(globals.scheduleRideDateFormat).format(selectedDateTime.value)} at ${DateFormat(globals.scheduleRideTimeFormat).format(selectedDateTime.value)} - ${DateFormat(globals.scheduleRideTimeFormat).format(getTimeByAddMin(selectedDateTime.value, 10))}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.BLACK_TEXT_COLOR,
                                  fontFamily: AppFont.font,
                                  fontSize: AppDimen.text_size_16),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              DateTime? ldDatePicked = await showDatePicker(
                                  helpText: "",
                                  context: context,
                                  cancelText: 'cancel_label'.tr,
                                  confirmText: 'ok_label'.tr,
                                  initialDate: selectedDateTime.value,
                                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                                  firstDate: getCurrentDateTime(),
                                  lastDate: getDateByAddMonth(getCurrentDateTime(), 1),
                                  builder: (BuildContext? context, Widget? child) {
                                    return globals.isDarkTheme
                                        ? Theme(
                                            data: ThemeData.dark().copyWith(
                                              textTheme: TextTheme(
                                                bodySmall: TextStyle(color: AppColors.PRIMARY_DARK_COLOR),
                                                bodyMedium: TextStyle(color: AppColors.PRIMARY_DARK_COLOR),
                                                bodyLarge: TextStyle(color: AppColors.PRIMARY_DARK_COLOR),
                                                titleLarge: TextStyle(color: AppColors.PRIMARY_DARK_COLOR),
                                                displayLarge: TextStyle(color: AppColors.PRIMARY_DARK_COLOR),
                                              ),
                                              dialogTheme: DialogThemeData(backgroundColor: AppColors.WHITE),
                                              datePickerTheme: DatePickerThemeData(
                                                headerForegroundColor: AppColors.PRIMARY_DARK_COLOR,
                                                dividerColor:  AppColors.PRIMARY_DARK_COLOR,
                                              ),
                                              colorScheme: ColorScheme.dark(
                                                primary: AppColors.PRIMARY_DARK_COLOR,
                                                surface: AppColors.PRIMARY_LIGHT_COLOR,
                                                onSurface: AppColors.PRIMARY_DARK_COLOR,
                                              ),
                                              textButtonTheme: TextButtonThemeData(
                                                  style: TextButton.styleFrom(
                                                      textStyle: TextStyle(fontFamily: AppFont.font))),
                                            ),
                                            child: child!,
                                          )
                                        : Theme(
                                            data: ThemeData.light().copyWith(
                                              datePickerTheme: DatePickerThemeData(
                                                headerForegroundColor: AppColors.PRIMARY_DARK_COLOR,
                                                  dividerColor:  AppColors.PRIMARY_DARK_COLOR
                                              ),
                                              colorScheme:
                                                  ColorScheme.light(primary: AppColors.PRIMARY_DARK_COLOR),
                                              textButtonTheme: TextButtonThemeData(
                                                  style: TextButton.styleFrom(
                                                      textStyle: TextStyle(fontFamily: AppFont.font))),
                                            ),
                                            child: child!,
                                          );
                                  });
                              if (ldDatePicked != null) {
                                selectedDateTime(DateTime(
                                    ldDatePicked.year,
                                    ldDatePicked.month,
                                    ldDatePicked.day,
                                    selectedDateTime.value.hour,
                                    selectedDateTime.value.minute));
                              }
                            },
                            child: Container(
                              margin: const EdgeInsetsDirectional.only(start: 24, end: 24, top: 20.0),
                              decoration: BoxDecoration(
                                color: AppColors.COMMON_BG_COLOR,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsetsDirectional.all(15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    calendarSvg,
                                    height: 17,
                                    width: 17,
                                    colorFilter:
                                        ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                  ),
                                  const SizedBox(
                                    width: 10.0,
                                  ),
                                  Text(
                                    'date'.tr +
                                        ": ${DateFormat(globals.scheduleRideDateFormat).format(selectedDateTime.value)}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
                                        fontFamily: AppFont.font,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_16),
                                  )
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              Localizations.localeOf(context);
                              TimeOfDay? ltTimePicked = await showTimePicker(
                                context: context,
                                cancelText: 'cancel_label'.tr,
                                confirmText: 'ok_label'.tr,
                                hourLabelText: '',
                                minuteLabelText: '',
                                helpText: 'confirm_label'.tr,
                                initialTime: TimeOfDay.fromDateTime(selectedDateTime.value),
                                builder: (context, child) {
                                  final Widget mediaQueryWrapper = MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      alwaysUse24HourFormat: true,
                                    ),
                                    child: child!,
                                  );
                                  return globals.isDarkTheme
                                      ? Theme(
                                          data: ThemeData.dark().copyWith(
                                            colorScheme: ColorScheme.dark(
                                              primary: AppColors.PLACEHOLDER_TEXT_COLOR,
                                              surface: AppColors.PRIMARY_LIGHT_COLOR,
                                              onSurface: AppColors.PRIMARY_DARK_COLOR,
                                            ),
                                            textButtonTheme: TextButtonThemeData(
                                                style: TextButton.styleFrom(
                                                    textStyle: TextStyle(
                                              fontFamily: AppFont.font,
                                              color: AppColors.PRIMARY_DARK_COLOR,
                                            ))),
                                            timePickerTheme: TimePickerThemeData(
                                              helpTextStyle: TextStyle(
                                                color: AppColors.PRIMARY_DARK_COLOR,
                                              ),
                                              hourMinuteTextColor: AppColors.PRIMARY_DARK_COLOR,
                                            ),
                                            dialogTheme: DialogThemeData(backgroundColor: AppColors.WHITE),
                                          ),
                                          child: mediaQueryWrapper)
                                      : Theme(
                                          data: ThemeData.light().copyWith(
                                            colorScheme:
                                                ColorScheme.light(primary: AppColors.PRIMARY_DARK_COLOR),
                                            textButtonTheme: TextButtonThemeData(
                                                style: TextButton.styleFrom(
                                                    textStyle: TextStyle(fontFamily: AppFont.font))),
                                          ),
                                          child: mediaQueryWrapper,
                                        );
                                },
                              );
                              if (ltTimePicked != null) {
                                selectedDateTime(DateTime(
                                    selectedDateTime.value.year,
                                    selectedDateTime.value.month,
                                    selectedDateTime.value.day,
                                    ltTimePicked.hour,
                                    ltTimePicked.minute));
                              }
                            },
                            child: Container(
                              margin: const EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 15),
                              decoration: BoxDecoration(
                                color: AppColors.COMMON_BG_COLOR,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsetsDirectional.all(15.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    clockSvg,
                                    height: 17,
                                    width: 17,
                                    colorFilter:
                                        ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
                                  ),
                                  const SizedBox(
                                    width: 10.0,
                                  ),
                                  Text(
                                    'Time'.tr +
                                        ": ${DateFormat(globals.scheduleRideTimeFormat).format(selectedDateTime.value)} - ${DateFormat(globals.scheduleRideTimeFormat).format(getTimeByAddMin(selectedDateTime.value, 10))}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppColors.BLACK_TEXT_COLOR,
                                        fontFamily: AppFont.font,
                                        fontWeight: FontWeight.w500,
                                        fontSize: AppDimen.text_size_16),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                                start: 24.0,
                                end: 24.0,
                                top: 30.0,
                                bottom: widget.isScheduleRideIconEnable
                                    ? widget.pickUpPlace != "" && widget.dropOffPlace != ""
                                        ? 0.0
                                        : 10.0
                                    : 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    child: Container(
                                      height: 50,
                                      margin: const EdgeInsetsDirectional.only(end: 10),
                                      decoration: BoxDecoration(
                                          color: AppColors.PRIMARY_LIGHT_COLOR,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(width: 1, color: AppColors.PRIMARY_DARK_COLOR)),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'cancel_label'.tr,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: AppDimen.text_size_18,
                                              color: AppColors.BLACK_TEXT_COLOR),
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      widget.scheduleRideControllerIF
                                          .scheduleRideController("cancel screen", selectedDateTime.value);
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      if (widget.isEdit) {
                                        if (checkSelectedDate(selectedDateTime.value)) {
                                          widget.scheduleRideControllerIF
                                              .scheduleRideController("confirm", selectedDateTime.value);
                                        } else {
                                          App().toast.show(
                                              context: context,
                                              message: 'Invalid_Schedule_Time'.trParams(
                                                  {'field2': globals.scheduleRestrictionTime.toString()}));
                                        }
                                      } else {
                                        if (widget.pickUpPlace.isEmpty || widget.dropOffPlace.isEmpty) {
                                          if (checkSelectedDate(selectedDateTime.value)) {
                                            widget.scheduleRideControllerIF
                                                .scheduleRideController("select", selectedDateTime.value);
                                          } else {
                                            App().toast.show(
                                                context: context,
                                                message: 'Invalid_Schedule_Time'.trParams(
                                                    {'field2': globals.scheduleRestrictionTime.toString()}));
                                          }
                                        } else {
                                          if (checkSelectedDate(selectedDateTime.value)) {
                                            widget.scheduleRideControllerIF
                                                .scheduleRideController("next", selectedDateTime.value);
                                          } else {
                                            App().toast.show(
                                                context: context,
                                                message: 'Invalid_Schedule_Time'.trParams(
                                                    {'field2': globals.scheduleRestrictionTime.toString()}));
                                          }
                                        }
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsetsDirectional.only(start: 10),
                                      decoration: BoxDecoration(
                                          color: AppColors.PRIMARY_DARK_COLOR,
                                          borderRadius: BorderRadius.all(const Radius.circular(5))),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsetsDirectional.all(10.0),
                                            child: Text(
                                              !widget.isEdit
                                                  ? widget.pickUpPlace.isEmpty || widget.dropOffPlace.isEmpty
                                                      ? 'Set'.tr
                                                      : 'Next'.tr
                                                  : 'confirm_label'.tr,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontFamily: AppFont.font,
                                                  fontSize: AppDimen.text_size_18,
                                                  color: AppColors.WHITE_TEXT_COLOR),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional.only(top: 2),
                                            child: RotatedBox(
                                              quarterTurns: globals.isRTLLang ? 2 : 0,
                                              child: SvgPicture.asset(
                                                primaryBtnArrow,
                                                colorFilter: ColorFilter.mode(
                                                    AppColors.PRIMARY_LIGHT_COLOR, BlendMode.srcIn),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          widget.isScheduleRideIconEnable
                              ? !widget.isEdit
                                  ? widget.pickUpPlace.isNotEmpty && widget.dropOffPlace.isNotEmpty
                                      ? Padding(
                                          padding: const EdgeInsetsDirectional.only(
                                              start: 20.0, end: 20.0, bottom: 20.0),
                                        )
                                      : const SizedBox.shrink()
                                  : const SizedBox.shrink()
                              : const SizedBox.shrink(),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            )));
  }

  DateTime getTimeByAddMin(DateTime dateTime, int minToAdd) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute + minToAdd);
  }

  DateTime getDateByAddMonth(DateTime dateTime, int monthToAdd) {
    return DateTime(dateTime.year, dateTime.month + monthToAdd, dateTime.day, dateTime.hour, dateTime.minute);
  }

  DateTime getCurrentDateTime() {
    return DateTime.now();
  }

  bool checkSelectedDate(DateTime date) {
    if (date.isAfter(getTimeByAddMin(getCurrentDateTime(), globals.scheduleRestrictionTime))) {
      return true;
    } else {
      return false;
    }
  }

  @override
  void dispose() {
    selectedDateTime.close();
    super.dispose();
  }
}

class ScheduleRideControllerIF {
  void scheduleRideController(String data, DateTime selectedDateTime) {}
}