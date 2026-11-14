import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/controller/profile_controllers/static_page_controller.dart';


import 'package:wooberly_driver/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_colors.dart';

class StaticPageStateLess extends StatelessWidget {
  final int staticPageContentId;
  final String staticPageTitle;
  StaticPageStateLess({required this.staticPageContentId,required this.staticPageTitle});

  @override
  Widget build(BuildContext context) {
    return StaticPageState(staticPageContentId: staticPageContentId,staticPageTitle: staticPageTitle,);
  }
}

class StaticPageState extends StatefulWidget {
  final int staticPageContentId;
  final String staticPageTitle;
  StaticPageState({required this.staticPageContentId,required this.staticPageTitle});

  @override
  State<StatefulWidget> createState() => StaticPageStateView();
}

class StaticPageStateView extends State<StaticPageState> {
  var rxContentController = ReactiveVariable("rxContentController", '');
  final StaticPageController _controller = Get.find();
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  late BuildContext scoffoldcontext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getStaticPageContent(widget.staticPageContentId).then((value) {
        _controller.change(rxVariable: rxContentController, value: value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
        key: _scaffoldKey,
        disableAppbar: false,
        appBarTitle: widget.staticPageTitle,
        body: Stack(
          children: [
            GetBuilder(
              init: StaticPageController(),
                id: rxContentController.id,
                builder: (val) {
                  return Padding(
                    padding: EdgeInsetsDirectional.only(
                        start: 20, end: 20, top: 20, bottom: 10),
                    child: SingleChildScrollView(
                      child:Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Consumer<ModelTheme>(builder:
                            (context, ModelTheme themeNotifier, child) {
                          return HtmlWidget(
                            rxContentController.value.replaceAll("\"", ""),
                            onTapUrl: (url) async {
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              }
                              return url != null;
                            },
                            textStyle: TextStyle(
                                color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                          );
                        },
                        ),
                      ),
                    ),
                  );
                }),
            GetBuilder(
              init: StaticPageController(),
                id: rxContentController.id,
                builder: (val) {
                  if (rxContentController.value == "") {
                    return _controller.getProgressIndicator(scoffoldcontext, AppColors.PRIMARY_COLOR_DARK.withValues(alpha:0.2));
                  } else {
                    return const SizedBox.shrink();
                  }
                })
          ],
        ),
        onChanged: (map) {
          scoffoldcontext = map["scaffoldcontext"];
          _scaffoldKey = map["scaffoldkey"];
        });
  }

  @override
  void dispose() {
    super.dispose();
  }

}