import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../resources/values/app_colors.dart';
import '../resources/values/app_dimen.dart';
import '../resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

class PrimaryAppBar extends StatefulWidget {
  final String? pageTitle;
  final String? backImage;
  final List<Widget>? actionWidgets;
  final VoidCallback? callback;
  final Color? BGColor;

  const PrimaryAppBar(
      {Key? key, this.pageTitle, this.backImage,this.actionWidgets, this.callback, this.BGColor})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PrimaryAppBarState();
  }
}

class PrimaryAppBarState extends State<PrimaryAppBar> {
  @override
  Widget build(BuildContext context) {
    final String title = widget.pageTitle ?? "";
    final String backImg = widget.backImage ?? "";

    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsetsDirectional.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: widget.BGColor ?? AppColors.COMMON_BG_COLOR,
      ),
      child: SizedBox(
        height: 75,
        child: Stack(
          children: [
            // ── Title: centered over the full AppBar width ──
            if (title.isNotEmpty)
              PositionedDirectional(
                // Adjust "start" to match your back icon's actual width + spacing
                start: (backImg.isNotEmpty && backImg != "hide") ? 45 : 0,
                end: (widget.actionWidgets != null && widget.actionWidgets!.isNotEmpty)
                    ? 80
                    : 16,
                top: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 22),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Obx(() {
                      globals.preferredLanguage.value;
                      debugPrint("preferredLanguage: appbar ${title}");
                   return   Text(
                        title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR,
                            fontFamily: AppFont.font,
                            fontSize: AppDimen.text_size_18),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      );
                    }),
                  ),
                ),
              ),

            // ── Back button: pinned to start ──
            if (backImg.isNotEmpty && backImg != "hide")
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: _showImage(),
              ),

            // ── Action widgets: pinned to end ──
            if (widget.actionWidgets != null && widget.actionWidgets!.isNotEmpty)
              PositionedDirectional(
                end: 24,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: widget.actionWidgets!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  _showImage() {
    final String backImg = widget.backImage ?? "";
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24.0),
      child: Center(
        child: InkWell(
          onTap: () {
            if (widget.callback != null) widget.callback!();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: widget.BGColor != null
                    ? AppColors.COMMON_BG_COLOR
                    : AppColors.PRIMARY_LIGHT_COLOR,
                shape: BoxShape.circle),
            child: SizedBox(
              width: widget.BGColor != null ? 12 : 40,
              height: widget.BGColor != null ? 21 : 40,
              child: RotatedBox(
                quarterTurns: globals.isRtlLang ? 2 : 0,
                child: SvgPicture.asset(
                  backImg,
                  fit: BoxFit.scaleDown,
                  colorFilter: ColorFilter.mode(AppColors.ICON_COLOUR, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}