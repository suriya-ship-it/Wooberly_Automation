import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/app/app_routes.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/controllers/add_card_controller.dart';
import '../../controllers/map_main_controller/map_main_controller.dart';import 'package:app_name/widgets/primary_scaffold.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class PayStackWebView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WebviewAccountView();
  }
}

class WebviewAccountView extends StatefulWidget {
  WebviewAccountView({Key? key}) : super(key: key);

  @override
  _WebviewAccountState createState() => new _WebviewAccountState();
}

class _WebviewAccountState extends State<WebviewAccountView> {
  MapMainController mapMainController= Get.find();
  AddCardController addCardController=Get.find();
  Map<String, dynamic>? arguments;
  RxBool loadingController = false.obs;
  late final WebViewController _controller;
  bool isFromPaypal=false;

  @override
  void initState() {
    arguments = Get.arguments;
    debugPrint("_addCardController.payStackURL: arguments ${Get.arguments}");
    _createController();
    if (!(globals.socket?.connected ?? false)) {
      globals.socket?.connect();
    }
    listenPayStackPaymentStatus("sendSocketNotification-${globals.userid}");
    super.initState();
  }



  listenPayStackPaymentStatus(String eventName) {
    globals.socket?.off("paystackPaymentStatus-${globals.userid}");
    globals.socket?.on("paystackPaymentStatus-${globals.userid}", (data) {
      if (data is Map) {
        if (data["data"]["status"] == 200) {
          if (data["data"]["data"]["PaymentSection"] == "booking" && data["data"]["data"]["status"] == 200) {
            mapMainController.tripFinalAmount = null;
            mapMainController.tripAmountController?.reverse();
            mapMainController.isFromtrips = false;
            mapMainController.clearMap();
            Get.offNamed(AppRoutes.APP_SHOW_REVIEW);
          } else if (data["data"]["data"]["PaymentSection"] == "wallet" && data["data"]["data"]["status"] == 200) {
            if(data["data"]["data"]["updatedWalletBalance"] !=null)
            globals.walletBalance.value = double.parse(data["data"]["data"]["updatedWalletBalance"].toString());
            if (globals.checkNavWallet == "updatePaymentToWallet") {
              mapMainController.updatepaymentMethod(3);
            }
            closePage("");
          }else{
            if(data["data"]["data"]["errorMessage"] != null){
            mapMainController.showInSnackBar( data["data"]["data"]["errorMessage"]);
            }
            closePage("close");
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if(arguments?['isFrom']!=null&&arguments?['isFrom']=='paypal')
      isFromPaypal=true;
    return PrimaryScaffold(
      disableAppbar: false,
      appBarTitle: isFromPaypal?'PayPal':"PayStack",
      customAppBarFunction: () {
        closePage("close");
      },
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        Obx(() {
              if (loadingController.value == true)
                return mapMainController.getProgressIndicator();
              else
                return const SizedBox.shrink();
            })
      ]),
    );
  }



  _createController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setBackgroundColor(AppColors.staticBlack)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress != 100) {
              loadingController(true);
            } else {
              loadingController(false);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final _request = request.url;
            debugPrint('Page finished loading: $_request');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse(arguments?['payStackURL']??addCardController.payPalURL));
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }


  closePage([String paymentStatus = ""]) {
    globals.setButtonIdle();
    Get.back(result: paymentStatus);
  }

 


}