import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/blinking_toast.dart';
class MyAppLifecycleHandler extends StatefulWidget {
  final Widget child;
  final BaseController controller=Get.find();

   MyAppLifecycleHandler({super.key, required this.child});

  @override
  State<MyAppLifecycleHandler> createState() => _MyAppLifecycleHandlerState();
}

class _MyAppLifecycleHandlerState extends State<MyAppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    widget.controller.clearNotification();
    Toast.dismiss();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    super.didHaveMemoryPressure();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {

    debugPrint("App lifeCycle ---> ${state} --- ${Get.currentRoute} -- ${globals.authToken}");
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // Clear non-visible bitmap memory usage when in background/cached state
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      widget.controller.clearNotification();
      Toast.dismiss();
    } else if(state == AppLifecycleState.resumed && globals.authToken !=null && globals.authToken!.isNotEmpty){
      widget.controller.checkUserLogin().then((value){
        debugPrint("checkUserLogin: ${value}");
        if(!value){
          widget.controller.setLogout();
        }
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}