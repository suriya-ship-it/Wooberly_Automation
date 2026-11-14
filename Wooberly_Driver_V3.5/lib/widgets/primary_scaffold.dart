import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/auth_controllers/splash_controller.dart';

import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/widgets/primary_appbar.dart';

import '../app/model_theme.dart';
import '../controller/base_controller.dart';
import '../controller/home_controllers/map_main_controller/map_main_controller.dart';
import '../resources/values/app_images.dart';
import '../utils/globals.dart' as globals;

class PrimaryScaffold extends StatefulWidget {
  static bool avoidLoader = false;
  static dynamic updatedLoader = null;

  const PrimaryScaffold({
    Key? key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.appBarSize,
    this.bottomSheet,
    this.isAppBarSize,
    this.backgroundColor,
    this.resizeToAvoidBottomPadding,
    this.resizeToAvoidBottomInset = false,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.customBottomSheet = null,
    this.disableAppbar = false,
    this.appBarTitle = "",
    this.customAppBarContent,
    this.actionWidgets,
    this.customAppBarFunction,
    this.appBarImage,
    this.customScaffoldcontextFunction = null,
    this.loader,
    this.loaderBackgroundColor,
    this.onChanged,
  })  : assert(primary != null),
        assert(extendBody != null),
        assert(extendBodyBehindAppBar != null),
        assert(drawerDragStartBehavior != null),
        super(key: key);

  final bool extendBody;

  final bool extendBodyBehindAppBar;

  final PreferredSizeWidget? appBar;

  final Widget? body;

  final Widget? floatingActionButton;

  final FloatingActionButtonLocation? floatingActionButtonLocation;

  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  final List<Widget>? persistentFooterButtons;

  final List<Widget>? actionWidgets;

  final Widget? drawer;

  final Widget? endDrawer;

  final Color? drawerScrimColor;

  final Color? backgroundColor;

  final Widget? bottomNavigationBar;

  final Widget? bottomSheet;

  final bool? resizeToAvoidBottomPadding;

  final bool resizeToAvoidBottomInset;

  final DragStartBehavior drawerDragStartBehavior;

  final double? drawerEdgeDragWidth;

  final bool primary;

  final bool? isAppBarSize;

  final double? appBarSize;

  final bool disableAppbar;

  final String appBarTitle;

  final String? appBarImage;

  final Widget? customBottomSheet;

  final dynamic customAppBarContent;

  final Function? customAppBarFunction;

  final Function? customScaffoldcontextFunction;

  final String? loader;

  final Color? loaderBackgroundColor;

  final ValueChanged<Map<String, dynamic>>? onChanged;

  @override
  CustomScaffoldState createState() => CustomScaffoldState();
}

class CustomScaffoldState extends State<PrimaryScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  BuildContext? scoffoldcontext;
  final SplashController controller = Get.find();
  final MapMainController mapMainController = Get.find();

  Color? loadercolor;

  Map<String, dynamic>? returnMap;

  @override
  void initState() {
    if (widget.customScaffoldcontextFunction != null) {
      Future.delayed(const Duration(milliseconds: 20), () {
        controller.checkInternet(widget.customScaffoldcontextFunction!, false);
      });
    }
    returnMap = Map<String, dynamic>();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid)
      if(globals.isDarkTheme)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              systemNavigationBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Colors.black,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
              statusBarColor: AppColors.PRIMARY_COLOR_WHITE, // status bar color
            ),
          );
        });
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child) {
      return Container(
        color: AppColors.PRIMARY_COLOR_WHITE,
        child: SafeArea(
          child: PopScope(
            canPop: widget.customAppBarFunction == null,
            onPopInvokedWithResult: (didPop,onPopInvokedWithResult) {
              if (didPop) {
                return;
              }
              if (widget.customAppBarFunction != null)
                widget.customAppBarFunction!();
            },
            child: Scaffold(
              key: _scaffoldKey,
              appBar: widget.disableAppbar
                  ? null
                  : widget.customAppBarContent != null
                      ? widget.customAppBarContent
                      : PreferredSize(
                          preferredSize:const Size.fromHeight(75),
                          child: PrimaryAppBar(
                            pageTitle: widget.appBarTitle,
                            backImage: widget.appBarImage ?? primaryLeftArrow,
                            actionWidgets: widget.actionWidgets,
                            callback: () {
                              mapMainController.isRecording.value = false;
                              if (widget.customAppBarFunction != null)
                                widget.customAppBarFunction!();
                              else
                                App().setBackNavigation();
                            },
                          ),
                        ),
              resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
              backgroundColor: AppColors.COMMON_BG_COLOR,
              floatingActionButton: widget.floatingActionButton,
              bottomNavigationBar: widget.bottomNavigationBar,
              floatingActionButtonLocation: widget.floatingActionButtonLocation,
              endDrawer: widget.endDrawer,
              body: Builder(
                builder: (BuildContext ctx) {
                  scoffoldcontext = ctx;
                  _publishSelection("scaffoldcontext", scoffoldcontext!,
                      "scaffoldkey", _scaffoldKey);
                  return Stack(
                    children: <Widget>[
                      widget.body!,
                      _showProgressIndicator(scoffoldcontext!),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }

  _showProgressIndicator(BuildContext context) {
    return GetBuilder<BaseController>(
        init: globals.baseController,
        id: globals.rxLoadingController.id,
        builder: (val) {
          if (globals.rxLoadingController.value != null &&
              globals.rxLoadingController.value == 0 &&
              !PrimaryScaffold.avoidLoader &&
              PrimaryScaffold.updatedLoader != null)
            return controller.getProgressIndicator(context, AppColors.PRIMARY_COLOR_DARK,
                loader: PrimaryScaffold.updatedLoader);
          else
            return const SizedBox.shrink();
        });
  }

  void _publishSelection(
      String key, dynamic value, String key1, dynamic value1) {
    returnMap![key] = value;
    returnMap![key1] = value1;

    if (widget.onChanged != null) {
      widget.onChanged!(returnMap!);
    }
  }
}