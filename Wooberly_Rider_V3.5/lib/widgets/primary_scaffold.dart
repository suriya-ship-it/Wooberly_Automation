import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/app/enums/button_state.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/controllers/base_controller.dart';
import 'package:app_name/widgets/primary_appbar.dart';

import '../app/app_routes.dart';
import '../app/model_theme.dart';
import '../resources/values/app_images.dart';
import '../utils/globals.dart';
import 'language_dialog.dart';
import 'package:rxdart/subjects.dart' show BehaviorSubject;


class PrimaryScaffold extends StatefulWidget {

static RxBool avoidLoader=false.obs;
static bool isLoading = false;
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
    this.appBarImage = null,
    this.customAppBarContent,
    this.customAppBarFunction,
    this.actionWidgets,
    this.customScaffoldcontextFunction=null,
    this.loader = 'loader',
    this.loaderBackgroundColor,

    this.onChanged,
  })
      : assert(primary != null),
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

  final bool? disableAppbar;

  final String appBarTitle;

  final String? appBarImage;

  final Widget? customBottomSheet;

  final dynamic customAppBarContent;

  final Function? customAppBarFunction;

  final Function? customScaffoldcontextFunction;

  final String loader;

  final Color? loaderBackgroundColor;

  final ValueChanged<Map<String, dynamic>>? onChanged;

  @override
  CustomScaffoldState createState() => CustomScaffoldState();
}

class CustomScaffoldState extends State<PrimaryScaffold>{

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  BaseController controller=Get.find();
  BuildContext? scoffoldcontext;

  Color? loadercolor ;
  Map<String, dynamic>? returnMap;


  @override
  void initState() {
    if(widget.customScaffoldcontextFunction != null) {
      Future.delayed(const Duration(milliseconds: 20), () {
        controller.checkInternet( widget.customScaffoldcontextFunction!,false);
      });
    }
    returnMap =  Map<String,dynamic>();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(globals.navigateToTripsPast && !Get.currentRoute.contains('trips')) {
        controller.setNavigation(AppRoutes.APP_TRIPS);
      }
    });
    if (Platform.isAndroid)
      if(globals.isDarkTheme)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              systemNavigationBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Colors.black,
              statusBarIconBrightness: Brightness.light,
              statusBarColor: AppColors.PRIMARY_LIGHT_COLOR,
            ),
          );
        });
    return Consumer<ModelTheme>(
        builder: (context, ModelTheme themeNotifier, child)
    {
      return ColoredBox(
        color: widget.backgroundColor ?? AppColors.PRIMARY_LIGHT_COLOR,
        child: SafeArea(
          child: PopScope(
            canPop: widget.customAppBarFunction == null,
            onPopInvokedWithResult: (didPop,onPopInvokedWithResult) {
              if (!didPop) {
                if (widget.customAppBarFunction != null)
                  widget.customAppBarFunction!();
              }
            },
            child: Scaffold(
              key: _scaffoldKey,
              appBar:
               widget.disableAppbar == true ? const PreferredSize(
                   preferredSize: const Size.fromHeight(0),
                   child: const SizedBox.shrink()):
               widget.customAppBarContent != null ?
               widget.customAppBarContent :
              PreferredSize(
                preferredSize: const Size.fromHeight(75),
                child: PrimaryAppBar(
                  pageTitle: widget.appBarTitle,
                  backImage:widget.appBarImage ?? primaryLeftArrow,
                  actionWidgets: widget.actionWidgets,

                  callback: () {
                    if (widget.customAppBarFunction != null)
                      widget.customAppBarFunction!();
                    else {
                      globals.setButtonIdle();
                     controller.setBackNavigation();
                    }
                  },
                ),
              ),
              resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
              backgroundColor: AppColors.COMMON_BG_COLOR,
              floatingActionButton: widget.floatingActionButton,
              bottomNavigationBar: widget.bottomNavigationBar,
              floatingActionButtonLocation: widget.floatingActionButtonLocation,
              endDrawer: widget.endDrawer,
              body:  Builder(
                builder: (BuildContext ctx) {
                  scoffoldcontext = ctx;
                  _publishSelection(
                      "scaffoldcontext", scoffoldcontext, "scaffoldkey",
                      _scaffoldKey);
                  return Stack(
                    children: <Widget>[
                      widget.body!,
                      Obx ((){
                        debugPrint("PrimaryScaffold.isLoading: ${PrimaryScaffold.avoidLoader.value} -- ${widget.loader}");
                          return Visibility(
                            visible: !PrimaryScaffold.avoidLoader.value && widget.loader.isNotEmpty,
                              child: _showProgressIndicator(scoffoldcontext!)
                          );
                        }
                      ),
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
    return Obx((){
            PrimaryScaffold.isLoading =globals.buttonState.value ==ButtonState.loading;
            if (globals.buttonState.value ==ButtonState.loading && !PrimaryScaffold.avoidLoader.value)
              return controller.getProgressIndicator();
            else
              return const SizedBox.shrink();
    }
    );

  }

  void _publishSelection(String key, dynamic value,String key1, dynamic value1) {
    returnMap![key] = value;
    returnMap![key1] = value1;

    if (widget.onChanged != null) {
      widget.onChanged!(returnMap!);
    }



  }


}