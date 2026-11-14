import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/widgets/primary_scaffold.dart';

import '../app/model_theme.dart';
import '../resources/values/app_colors.dart';
import '../controllers/static_page_controller.dart';

class StaticPageStateLess extends StatelessWidget {
  final int staticPageContentId;
  final String staticPageTitle;

  StaticPageStateLess({required this.staticPageContentId, required this.staticPageTitle});

  @override
  Widget build(BuildContext context) {
    return StaticPageState(
      staticPageContentId: staticPageContentId,
      staticPageTitle: staticPageTitle,
    );
  }
}

class StaticPageState extends StatefulWidget {
  final int staticPageContentId;
  final String staticPageTitle;

  StaticPageState({required this.staticPageContentId, required this.staticPageTitle});

  @override
  State<StatefulWidget> createState() => StaticPageStateView();
}

class StaticPageStateView extends State<StaticPageState> {
  RxString contentController = ''.obs;
  final StaticPageController _staticPageController = Get.find();
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  late BuildContext scoffoldcontext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staticPageController.getStaticPageContent(widget.staticPageContentId).then((value) {
        contentController(value);
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
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 20, end: 20, top: 20, bottom: 10),
              child: SingleChildScrollView(
                child: Align(
                  alignment:  AlignmentDirectional.centerStart,
                  child: Consumer<ModelTheme>(builder: (context, ModelTheme themeNotifier, child) {
                    return Obx(
                      () => HtmlWidget(
                        contentController.value.replaceAll("\"", "") ?? '',
                        onTapUrl: (url) async {
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                          return url != null;
                        },
                        textStyle: TextStyle(color: AppColors.BLACK_TEXT_COLOR),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Obx(() {
              debugPrint("contentController: ${contentController.value}");
              if (contentController.value == "") {
                return _staticPageController.getProgressIndicator();
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
    contentController.close();
    super.dispose();
  }
}