import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:app_name/utils/globals.dart' as globals;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (backImg.isNotEmpty && backImg != "hide") _showImage(backImg),
          Container(
            width:  backImg.isNotEmpty && widget.backImage != "hide"
                ? MediaQuery.of(context).size.width * 0.68
                : MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            margin:  EdgeInsetsDirectional.only(top: 22,end:  backImg.isNotEmpty && backImg != "hide" ? 25 : 0) ,
            child: Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.BLACK_TEXT_COLOR,
                  fontFamily: AppFont.font,
                  fontSize: AppDimen.text_size_18),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          if(widget.actionWidgets !=null && widget.actionWidgets!.isNotEmpty)
            ...widget.actionWidgets!,


        ],
      ),
    );
  }

  _showImage(String backImg) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24.0, top: 22.0),
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
              quarterTurns: globals.isRTLLang ? 2:0,
              child:
              SvgPicture.asset(
                backImg,
                fit: BoxFit.scaleDown,

                colorFilter: ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}