import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:app_name/controllers/base_controller.dart';
import '../resources/values/app_colors.dart';
import '../controllers/add_card_controller.dart';
import 'package:app_name/utils/globals.dart' as globals;

import '../widgets/primary_scaffold.dart';
import '../widgets/spin_kit/three_bounce.dart';

class PayPalWebView extends StatelessWidget {
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
  final AddCardController addCardController = Get.find();
  Map<String, dynamic> arguments = {};
  WebViewController _controller = WebViewController();
  var rxLoadingController = RxVariable(id: "rxLoadingController", value: false);
  bool isConfirmBookingApiCalled = false;
  bool isFromPaypal = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createController();
    });
    super.initState();
  }

  _createController() {
    arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    controller
      ..setBackgroundColor(AppColors.staticBlack)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) {
          if (progress != 100) {
            addCardController.updateRxValue(rxLoadingController, true);
          } else {
            if (!isConfirmBookingApiCalled)
              addCardController.updateRxValue(rxLoadingController, false);
          }
        },
        onNavigationRequest: (request) {
          debugPrint("onNavigationRequest: ${request.url}");
          if (request.url.contains('/payment-success')) {
            _confirmBookingPayment('/payment-success');
          } else if (request.url.contains('/payment-failure')) {
            _confirmBookingPayment('/payment-failure');
          }

          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..addJavaScriptChannel("Toaster", onMessageReceived: (javaScriptMessage) {
        Get.showSnackbar(GetSnackBar(
          backgroundColor: Colors.black,
          messageText: Text(
            javaScriptMessage.message,
            style: TextStyle(color: Colors.white),
          ),
          duration: Duration(seconds: 3),
          animationDuration: Duration(milliseconds: 500),
        ));
      })
      ..loadRequest(Uri.parse(arguments['payPalURL']))
      ..setUserAgent('User_Agent');
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (Get.arguments != null) {
      arguments = Get.arguments;
      if (arguments['isFrom'] != null && arguments['isFrom'] == 'paypal')
        isFromPaypal = true;
    }
    return PrimaryScaffold(
      disableAppbar: false,
      appBarTitle: isFromPaypal ? 'PayPal' : "PayStack",
      customAppBarFunction: () {
        closePage("close");
      },
      body: Stack(children: [
        GetBuilder(
            init: addCardController,
            id: rxLoadingController.id,
            builder: (val) {
              return WebViewWidget(controller: _controller);
            }),
        GetBuilder(
            init: addCardController,
            id: rxLoadingController.id,
            builder: (val) {
              if (rxLoadingController.value)
                return Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: isConfirmBookingApiCalled
                      ? AppColors.PRIMARY_LIGHT_COLOR
                      : Colors.transparent,
                  child: SpinKitThreeBounce(
                    color: AppColors.PRIMARY_DARK_COLOR,
                    size: 22.0,
                  ),
                );
              else
                return const SizedBox.shrink();
            }),
      ]),
      onChanged: (map) {},
    );
  }

  void _confirmBookingPayment(String paymentStatus) {
    debugPrint("_confirmBookingPayment: ${paymentStatus}");
    if (paymentStatus == '/payment-success') {
      isConfirmBookingApiCalled = true;
      addCardController.updateRxValue(rxLoadingController, true);
      if (arguments["isFrom"] == "bookingPayment") {
        closePage("");
      } else {
        addCardController.getWalletBalance().then((value) {
          addCardController.walletAmount.clear();
          if (globals.checkNavWallet == "updatePaymentToWallet") {
            addCardController.updatepaymentMethod(3);
          }
          closePage("");
        });
      }
    } else {
      closePage("close");
      isConfirmBookingApiCalled = false;
    }
  }

  closePage([String paymentStatus = '']) {
    debugPrint("_confirmBookingPayment: closePage ${paymentStatus}");
    globals.setButtonIdle();
    Get.back(result: paymentStatus);
  }
}