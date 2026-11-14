import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/app/app_routes.dart';
import 'package:wooberly_driver/controller/trip_controllers/payout_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/primary_scaffold.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../resources/values/app_lang.dart';

class WebviewStripe extends StatelessWidget {
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
  final PayoutController payoutController = Get.find();
  late final WebViewController _controller;
  List<Permission> _Permission = [
    Permission.storage,
    Permission.camera,
  ];

  @override
  void initState() {
    requestPermission(_Permission);
    _createController();
    super.initState();
  }

  requestPermission(List<Permission> permission) async {
    await permission.request();
  }

  _createController(){
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
      ..setBackgroundColor(Colors.white)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('User_Agent')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress != 100) {
              payoutController.setLoadingController(true);
            } else {
              payoutController.setLoadingController(false);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final _request = request.url;
            if (_request.contains('/payout/success')) {
              payoutController.checkInternet(confirmPayout, false);
            } else if (_request.contains('/payout/failure')) {
              payoutController.checkInternet(showErrorToast, false);
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          Get.showSnackbar(

              GetSnackBar(
            messageText: Text(message.message),
          ));
        },
      )
      ..loadRequest(Uri.parse('${globals.stripeConnectionUrl}'));
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
      (controller.platform as AndroidWebViewController).setOnPlatformPermissionRequest((request) {
        request.grant();
        });
    }
    _controller = controller;
    addFileSelectionListener();
  }

  void addFileSelectionListener() {
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      final AndroidWebViewController androidController = _controller.platform as AndroidWebViewController;
      androidController.setOnShowFileSelector(_androidFilePicker);
    }
  }

  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    PlatformFile? result = await FilePicker.pickFile();
    if (result != null && result.path !=null && result.path!.isNotEmpty) {
      return [Uri.file(result.path!).toString() ];
    }
    return [];
  }


  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      customAppBarFunction: () {
        _controller.canGoBack().then((value){
          if(value) {
            _controller.goBack();
          }else{
            Get.until((route) => route.settings.name == "/AccountDisplay");
          }
        });

      },
      disableAppbar: false,
      appBarTitle: stripe_verify.tr,
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        GetBuilder(
          init: PayoutController(),
            id: payoutController.rxLoadingController.id,
            builder: (val) {
              if (payoutController.rxLoadingController.value == true)
                return payoutController.getProgressIndicator(
                    context, AppColors.CIRCULAR_PROGRESS_BAR_LOADING_COLOR, loader: 'assets/lottieloader.json');
              else
                return SizedBox.shrink();
            })
      ]),

    );
  }

  void confirmPayout() {
    payoutController.confirmPayout().then((value) {
      payoutController.setLoadingController(false);
      if (value.isNotEmpty) {
        payoutController.showInSnackBar( value);
      } else {
        try {
          Get.until((route) => route.settings.name == "/AccountDisplay");
        } on Exception catch (exception) {
          Get.until((route) => route.settings.name == "/AccountDisplay");
        } catch (error) {
          Get.until((route) => route.settings.name == "/AccountDisplay");
        }
        Future.delayed(const Duration(milliseconds: 200), () {
          payoutController.rxPayoutStatusChangedController.value = true;
        });
      }
    });
  }

  void showErrorToast() {
    Get.dialog(
      Obx(
        () {
          return globals.isAutoThemeUpdated.value != null ? CupertinoAlertDialog(
            title: Text("Oops"),
            content: Text(
                "connect_your_bank_account_platform".tr),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text("okay".tr),
                onPressed: () {
                  App().setBackNavigation();
                },
              )
            ],
          ) : SizedBox.shrink();
        }
      ));
  }
}