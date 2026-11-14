import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/views/account_details.dart';
import 'package:wooberly_driver/views/account_display.dart';
import 'package:wooberly_driver/views/address_details.dart';
import 'package:wooberly_driver/views/app_chat.dart';
import 'package:wooberly_driver/views/currency_lang_preview.dart';
import 'package:wooberly_driver/views/delete_account.dart';
import 'package:wooberly_driver/views/document_main.dart';
import 'package:wooberly_driver/views/document_preview.dart';
import 'package:wooberly_driver/views/driver_wallet.dart';
import 'package:wooberly_driver/views/earnings.dart';
import 'package:wooberly_driver/views/edit_account.dart';
import 'package:wooberly_driver/views/google_place_search.dart';
import 'package:wooberly_driver/views/help.dart';
import 'package:wooberly_driver/views/main.dart';
import 'package:wooberly_driver/views/map_main_screen.dart';
import 'package:wooberly_driver/views/multi_document_upload_view.dart';
import 'package:wooberly_driver/views/namefields.dart';
import 'package:wooberly_driver/views/otp_verify.dart';
import 'package:wooberly_driver/views/phone_no_auth.dart';
import 'package:wooberly_driver/views/select_country.dart';
import 'package:wooberly_driver/views/splash.dart';
import 'package:wooberly_driver/views/toll_fee.dart';
import 'package:wooberly_driver/views/trip_detail.dart';
import 'package:wooberly_driver/views/trips.dart';
import 'package:wooberly_driver/views/update_payout_payment_type.dart';
import 'package:wooberly_driver/views/vehicle_details.dart';
import 'package:wooberly_driver/views/vehicle_preview.dart';
import 'package:wooberly_driver/views/web_view_stripe.dart';

import '../views/add_paypal_payout.dart';
import '../views/settings.dart';
import '../widgets/map_screen_widget/rider_review_transition_view.dart';

class AppRoutes {
  static const String APP_ROUTE_LOGIN = "/login";
  static const String APP_ROUTE_EDIT_ACC = "/edit_account";
  static const String APP_DOCUMENT_MAIN = "/document_main";
  static const String APP_MULTI_DOCUMENT_UPLOAD = "/MultiDocumentUpload";

  static const String APP_NAME_FIELDS = "/namefields";
  static const String APP_ROUTE_DETAILS = "/details";
  static const String APP_CITY_SEARCH = "/city_search";
  static const String APP_MAP_MAIN = "/map_main_screen";
  static const String APP_TRIPS = "/trips";
  static const String APP_SPLASH = "/splash";
  static const String APP_SELECT_COUNTRY = "/select_country";
  static const String APP_PAYOUT_ADDRESS = "/address_details";
  static const String APP_PAYOUT_ACCOUNT = "/account_details";
  static const String APP_PAYOUT_DISPLAY = "/AccountDisplay";
  static const String APP_DRIVER_WALLET = "/driver_wallet";
  static const String APP_PAYOUT_UPDATE = "/update_payout";
  static const String APP_WEBVIEW_DISPLAY = "/WebviewStripe";
  static const String APP_VEHICLE_PREVIEW = "/vehicle_preview";
  static const String APP_DOCUMENT_PREVIEW = "/document_preview";
  static const String APP_CURRENCY_LANGUAGE = "/currency_language";
  static const String APP_EARNINGS = "/earniing";

  static const String APP_PHONE_AUTH = "/phoneno_auth";
  static const String APP_OTP_VERIFY = "/otp_verify";
  static const String APP_TRIP_DETAIL = "/trip_detail";
  static const String APP_HELP_INFO = "/help_info";
  static const String APP_CHAT = "/App_Chat";
  static const String DELETE_ACCOUNT = "/Delete_Account";
  static const String APP_SHOW_REVIEW = "/show_review";
  static const String APP_SETTINGS = "/settings";
  static const String APP_PAYPAL_PAYOUT = "/payPal_Payout";


  Route getRoutes(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case APP_TRIPS:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => Trips(),
            fullscreenDialog: true,
          );
        }
      case APP_EARNINGS:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => Earnings(),
            fullscreenDialog: true,
          );
        }
      case APP_HELP_INFO:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => HelpInfo(),
            fullscreenDialog: true,
          );
        }
      case APP_ROUTE_EDIT_ACC:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => EditAccount(),
            fullscreenDialog: true,
          );
        }

      case APP_ROUTE_LOGIN:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => Main(),
            fullscreenDialog: true,
          );
        }

      case APP_SETTINGS:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => Settings(),
            fullscreenDialog: true,
          );
        }

      case APP_NAME_FIELDS:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => NameFields(),
          );
        }

      case APP_CITY_SEARCH:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => CitySearch(),
          );
        }

      case APP_ROUTE_DETAILS:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => VehicleDetails(),
          );
        }

      case APP_MULTI_DOCUMENT_UPLOAD:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => MultiDocumentUpload(),
          );
        }

      case APP_DOCUMENT_MAIN:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => DocumentMain(),
          );
        }

      case APP_MAP_MAIN:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => MapMainScreen(),
          );
        }

      case APP_SELECT_COUNTRY:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => SelectCountry(),
          );
        }

      case APP_PAYOUT_ADDRESS:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => PayoutAddress(),
          );
        }

      case APP_PAYOUT_ACCOUNT:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => PayoutAccount(),
          );
        }
      case APP_VEHICLE_PREVIEW:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => VehiclePreview(),
          );
        }

      case APP_DOCUMENT_PREVIEW:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => DocumentPreview(),
          );
        }

      case APP_PAYOUT_DISPLAY:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => AccountDisplay(),
          );
        }
        case APP_DRIVER_WALLET:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => DriverWallet(),
          );
        }
      case APP_PAYOUT_UPDATE:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => UpdatePayOutPaymentType(),
          );
        }
      case APP_WEBVIEW_DISPLAY:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => WebviewStripe(),
          );
        }


      case APP_SHOW_REVIEW:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => RiderReviewTransitionView(),
          );
        }
      case APP_CHAT:
        {
          return CupertinoPageRoute(
              settings: routeSettings,
              builder: (BuildContext context) => AppChat());
        }
      case DELETE_ACCOUNT:
        {
          return CupertinoPageRoute(
              settings: routeSettings,
              builder: (BuildContext context) => DeleteAccount());
        }
      case APP_PAYPAL_PAYOUT:
        {
          return CupertinoPageRoute(
              settings: routeSettings,
              builder: (BuildContext context) =>PayPalPayout());
        }
      default:
        {
          return CupertinoPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) => Splash(),
            fullscreenDialog: true,
          );
        }
    }
  }

  getWidget(String app_route_name) {
    switch (app_route_name) {
      case APP_HELP_INFO:
        {
          return HelpInfo();
        }
      case APP_EARNINGS:
        {
          return Earnings();
        }
      case APP_PAYPAL_PAYOUT:
        {
          return PayPalPayout();
        }
      case APP_TRIPS:
        {
          return Trips();
        }

      case APP_TRIP_DETAIL:
        {
          return TripDetail();
        }

      case APP_ROUTE_EDIT_ACC:
        {
          return EditAccount();
        }

      case APP_ROUTE_LOGIN:
        {
          return Main();
        }

      case APP_NAME_FIELDS:
        {
          return NameFields();
        }

      case APP_PHONE_AUTH:
        {
          return PhoneNoAuth();
        }
      case APP_OTP_VERIFY:
        {
          return OtpVerify();
        }

      case APP_CITY_SEARCH:
        {
          return CitySearch();
        }

      case APP_ROUTE_DETAILS:
        {
          return VehicleDetails();
        }

      case APP_MULTI_DOCUMENT_UPLOAD:
        {
          return MultiDocumentUpload();
        }

      case APP_DOCUMENT_MAIN:
        {
          return DocumentMain();
        }

      case APP_MAP_MAIN:
        {
          return MapMainScreen();
        }

      case APP_SELECT_COUNTRY:
        {
          return SelectCountry();
        }

      case APP_PAYOUT_ADDRESS:
        {
          return PayoutAddress();
        }

      case APP_PAYOUT_ACCOUNT:
        {
          return PayoutAccount();
        }
      case APP_VEHICLE_PREVIEW:
        {
          return VehiclePreview();
        }

      case APP_DOCUMENT_PREVIEW:
        {
          return DocumentPreview();
        }

      case APP_PAYOUT_DISPLAY:
        {
          return AccountDisplay();
        }
        case APP_DRIVER_WALLET:
        {
          return DriverWallet();
        }
      case APP_PAYOUT_UPDATE:
        {
          return UpdatePayOutPaymentType();
        }
      case APP_WEBVIEW_DISPLAY:
        {
          return WebviewStripe();
        }
      case APP_CURRENCY_LANGUAGE:
        {
          return CurrencyLanguagePreview();
        }

      case APP_SHOW_REVIEW:
        {
          return RiderReviewTransitionView();
        }
      case APP_CHAT:
        {
          return AppChat();
        }
      case DELETE_ACCOUNT:
        {
          return DeleteAccount();
        }
      case APP_SETTINGS:
        {
          return Settings();
        }
      default:
        {
          return Splash();
        }
    }
  }
}