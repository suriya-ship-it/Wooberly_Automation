import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_name/controllers/base_controller.dart';

class AppBuilder extends StatefulWidget {
  final Function() builder;

  const AppBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  AppBuilderState createState() => AppBuilderState();

  static AppBuilderState? of(BuildContext context) {
    return context.findAncestorStateOfType<AppBuilderState>();
  }
}

class AppBuilderState extends State<AppBuilder> {
  BaseController baseController=Get.find();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BaseController>(
      id:'appBuilder',
      builder: (_) {
        return widget.builder();
      },
    );
  }

  void rebuild() {
   baseController.update(['appBuilder']);
  }

 
}