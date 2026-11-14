import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:app_name/bindings/auth_binding.dart';
import 'package:app_name/bindings/home_binding.dart';
import 'package:app_name/views/booking_instructions.dart';
import 'package:app_name/views/confirm_schedule_ride.dart';
import 'package:app_name/views/app_chat.dart';
import 'package:app_name/views/currency_lang_preview.dart';
import 'package:app_name/views/delete_account.dart';
import 'package:app_name/views/edit_account.dart';
import 'package:app_name/views/google_place_search.dart';
import 'package:app_name/views/help.dart';
import 'package:app_name/views/main.dart';
import 'package:app_name/views/manage_contact.dart';
import 'package:app_name/views/map_main_screen.dart';
import 'package:app_name/views/namefields.dart';
import 'package:app_name/views/otp_verify.dart';
import 'package:app_name/views/payment_type.dart';
import 'package:app_name/views/phone_no_auth.dart';
import 'package:app_name/views/promo_code.dart';
import 'package:app_name/views/select_drop_location.dart';
import 'package:app_name/views/select_map_location.dart';
import 'package:app_name/views/settings.dart';
import 'package:app_name/views/show_tips.dart';
import 'package:app_name/views/splash.dart';
import 'package:app_name/views/trip_detail.dart';
import 'package:app_name/views/trips/trips.dart';
import 'package:app_name/views/wallet.dart';
import 'package:app_name/views/web_view_pay_stack.dart';
import '../views/home_screen.dart';
import '../views/show_review.dart';
import '../views/web_view_pay_pal.dart';

class AppRoutes {
  static const String APP_ROUTE_LOGIN = "/login";
  static const String APP_ROUTE_EDIT_ACC = "/edit_account";
  static const String APP_NAME_FIELDS = "/namefields";
  static const String APP_CITY_SEARCH = "/city_search";
  static const String APP_MAP_MAIN = "/map_main_screen";
  static const String APP_TRIPS = "/trips";
  static const String APP_SPLASH = "/splash";
  static const String APP_CURRENCY_LANGUAGE = "/currency_language";
  static const String APP_SHOW_TIP = "/show_tips";
  static const String APP_SHOW_REVIEW = "/show_review";

  static const String APP_PAYMENT_TYPE = "/payment_type";
  static const String APP_WALLET = "/wallet";
  static const String APP_PHONE_AUTH = "/phoneno_auth";
  static const String APP_OTP_VERIFY = "/otp_verify";
  static const String SELECT_DROP_LOCATION = "/drop_location";
  static const String APP_TRIP_DETAIL = "/trip_detail";
  static const String APP_SETTINGS = "/settings";
  static const String SCHEDULING_RIDE = "/scheduling_ride";
  static const String TRUSTED_CONTACT = "/manage_contact";

  static const String APP_PROMO_CODE = "/promo_code";
  static const String APP_HOME = "/home_screen";
  static const String APP_SUPPORT_INFO = "/support";
  static const String CONFIRM_SCHEDULE_RIDE = "/Confirm_Schedule_Ride";
  static const String BOOKING_INSTRUCTION_VIEW = "/Booking_Instructions_View";
  static const String APP_CHAT = "/App_Chat";
  static const String CUSTOM_STRIPE_PAYMENT = "/Custom_Stripe_Payment";
  static const String DELETE_ACCOUNT = "/Delete_Account";
  static const String APP_WEBVIEW_DISPLAY = "/PayStackWebView";
  static const String APP_PAYPAL_DISPLAY = "/PayPalWebView";
  Route getRoutes(RouteSettings routeSettings) {
    switch (routeSettings.name) {

        case APP_PHONE_AUTH:
        return GetPageRoute(
          settings: routeSettings,
          page: () => PhoneNoAuth(),
          fullscreenDialog: true,
          binding: AuthBinding(),
          transition: Transition.rightToLeft,
        );
        case APP_OTP_VERIFY:
        return GetPageRoute(
          settings: routeSettings,
          page: () => OtpVerify(),
          fullscreenDialog: true,
          transition: Transition.rightToLeft,
        );

      case TRUSTED_CONTACT:
        return GetPageRoute(
          settings: routeSettings,
          page: () => ManageContact(),
          fullscreenDialog: true,
          transition: Transition.rightToLeft,
        );

      case APP_TRIPS:
        return GetPageRoute(
          settings: routeSettings,
          page: () => Trips(false),
          fullscreenDialog: true,
          binding: HomeBinding(),
          transition: Transition.rightToLeft,
        );


      case SCHEDULING_RIDE:
        return GetPageRoute(
          settings: routeSettings,
          page: () => SchedulingRide(),
          fullscreenDialog: true,
          transition: Transition.rightToLeft,
        );

      case APP_SETTINGS:
        return GetPageRoute(
          settings: routeSettings,
          page: () => Settings(),
          fullscreenDialog: true,
          binding: HomeBinding(),
          transition: Transition.rightToLeft,
        );

      case APP_SUPPORT_INFO:
        return GetPageRoute(
          settings: routeSettings,
          page: () => Support(),
          fullscreenDialog: true,
          transition: Transition.rightToLeft,
        );

      case APP_ROUTE_EDIT_ACC:
        return GetPageRoute(
          settings: routeSettings,
          page: () => EditAccount(),
          fullscreenDialog: true,
          transition: Transition.rightToLeft,
        );

      case APP_ROUTE_LOGIN:
        return GetPageRoute(
          settings: routeSettings,
          page: () => Main(),
          binding: AuthBinding(),
          fullscreenDialog: true,
          transition: Transition.rightToLeft,
        );

      case APP_NAME_FIELDS:
        return GetPageRoute(
          settings: routeSettings,
          binding: HomeBinding(),
          page: () => NameFields(),
          transition: Transition.rightToLeft,
        );

      case APP_CITY_SEARCH:
        return GetPageRoute(
          settings: routeSettings,
          page: () => CitySearch(),
          transition: Transition.rightToLeft,
        );

      case APP_MAP_MAIN:
        return GetPageRoute(
          settings: routeSettings,
          page: () => MapMainScreen(),
          binding: HomeBinding(),
          transition: Transition.rightToLeft,
        );

      case APP_WEBVIEW_DISPLAY:
        return GetPageRoute(
          settings: routeSettings,
          page: () => PayStackWebView(),
          transition: Transition.rightToLeft,
        );
        case APP_PAYPAL_DISPLAY:
        return GetPageRoute(
          settings: routeSettings,
          page: () => PayPalWebView(),
          transition: Transition.rightToLeft,
        );

      case APP_HOME:
        return GetPageRoute(
          settings: routeSettings,
          page: () => HomeScreen(),
          binding: HomeBinding(),
          transition: Transition.rightToLeft,
        );

      case APP_PAYMENT_TYPE:
        return GetPageRoute(
          settings: routeSettings,
          page: () => PaymentType(),
          binding: HomeBinding(),
          transition: Transition.rightToLeft,
        );
        case APP_WALLET:
        return GetPageRoute(
          settings: routeSettings,
          page: () => Wallet(),
          binding: HomeBinding(),
          transition: Transition.rightToLeft,
        );

      case APP_PROMO_CODE:
        return GetPageRoute(
          settings: routeSettings,
          page: () => PromoCode(),
          transition: Transition.rightToLeft,
        );

      case APP_SHOW_TIP:
        return GetPageRoute(
          settings: routeSettings,
          page: () => showTipScreenLess(),
          transition: Transition.rightToLeft,
        );

      case APP_SHOW_REVIEW:
        return GetPageRoute(
          settings: routeSettings,
          page: () => showReview(),
          transition: Transition.rightToLeft,
        );

      case CONFIRM_SCHEDULE_RIDE:
        return GetPageRoute(
          settings: routeSettings,
          page: () => ConfirmScheduleRide(),
          transition: Transition.rightToLeft,
        );

      case BOOKING_INSTRUCTION_VIEW:
        return GetPageRoute(
          settings: routeSettings,
          page: () => BookingInstructionsViewState(),
          transition: Transition.rightToLeft,
        );

      case APP_CHAT:
        return GetPageRoute(
          settings: routeSettings,
          page: () => AppChat(),
          transition: Transition.rightToLeft,
        );

      case DELETE_ACCOUNT:
        return GetPageRoute(
          settings: routeSettings,
          page: () => DeleteAccount(),
          transition: Transition.rightToLeft,
        );
        case SELECT_DROP_LOCATION:
          bool isFrom=routeSettings.arguments is bool?routeSettings.arguments as bool:false;
        return GetPageRoute(
          settings: routeSettings,
          page: () => SelectDropLocation(isFrom),
          binding: HomeBinding(),
          transition: Transition.rightToLeft,
        );
        case APP_CURRENCY_LANGUAGE:
        return GetPageRoute(
          settings: routeSettings,
          page: () => CurrencyLanguagePreview(),
          binding: HomeBinding(),
          transition: Transition.rightToLeft,
        );
        case APP_TRIP_DETAIL:
        return GetPageRoute(
          settings: routeSettings,
          page: () => TripDetail(),
          transition: Transition.rightToLeft,
        );

      default:
        return GetPageRoute(
          settings: routeSettings,
          page: () => Splash(),
          fullscreenDialog: true,
          transition: Transition.rightToLeft,
        );
    }
  }

}