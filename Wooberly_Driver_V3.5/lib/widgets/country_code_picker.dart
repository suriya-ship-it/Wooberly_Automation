import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wooberly_driver/controller/auth_controllers/splash_controller.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/resources/values/app_colors.dart';
import 'package:wooberly_driver/resources/values/app_dimen.dart';
import 'package:wooberly_driver/resources/values/app_fonts.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/widgets/country_code.dart';
import 'package:wooberly_driver/widgets/country_codes.dart';
import 'package:wooberly_driver/widgets/selection_dialog.dart';

class CountryCodePicker extends StatefulWidget {
  final ValueChanged<CountryCode>? onChanged;
  final String? initialSelection;
  final List<String> favorite;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final bool showCountryOnly;
  String selected_code = "";
  final InputDecoration searchDecoration;
  final TextStyle? searchStyle;
  final WidgetBuilder? emptySearchBuilder;
  final double flagSize;

  final bool showOnlyCountryWhenClosed;

  final bool alignLeft;

  final bool showFlag;

  final bool showDialog;

  final bool removeflexible;

  final bool isFromEditPage;

  CountryCodePicker(
      {this.onChanged,
      this.initialSelection,
      this.favorite = const [],
      this.textStyle,
      this.padding = const EdgeInsets.all(0.0),
      this.showCountryOnly = false,
      this.searchDecoration = const InputDecoration(),
      this.searchStyle,
      this.emptySearchBuilder,
      this.showOnlyCountryWhenClosed = false,
      this.alignLeft = false,
      this.showFlag = true,
      this.showDialog = false,
      this.removeflexible = false,
      this.flagSize = 32.0,
      this.isFromEditPage = false});

  @override
  State<StatefulWidget> createState() {
    List<Map> jsonList = codes;

    List<CountryCode> elements = jsonList
        .map((s) => CountryCode(
              name: s['name'],
              code: s['code'],
              dialCode: s['dial_code'],
              flagUri: 'res/drawable/flags/${s['code'].toLowerCase()}.png',
            ))
        .toList();

    return new _CountryCodePickerState(elements);
  }
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  CountryCode? selectedItem;
  List<CountryCode> elements = [];
  List<CountryCode> favoriteElements = [];
  final SplashController controller = Get.find();

  _CountryCodePickerState(this.elements);

  @override
  Widget build(BuildContext context) => !widget.removeflexible
      ? InkWell(
          onTap: () {
            if (widget.showDialog) _showSelectionDialog();
          },
          child: GetBuilder(
            init: globals.baseController,
            id: globals.rxExistController.id,
            builder: (val) {
              return Container(
                alignment: AlignmentDirectional.center,
                decoration: BoxDecoration(
                    color: widget.isFromEditPage
                        ? AppColors.DIVIDER_COLOR
                        : AppColors.PRIMARY_COLOR_WHITE,
                    borderRadius: BorderRadius.all(const Radius.circular(3.0))),
                height: 52,
                width: 90,
                padding: widget.padding,
                child: Flex(
                  direction: Axis.horizontal,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    widget.showFlag
                        ? Flexible(
                            flex: widget.alignLeft ? 0 : 1,
                            fit: widget.alignLeft ? FlexFit.tight : FlexFit.loose,
                            child: Padding(
                              padding: widget.alignLeft
                                  ? globals.isRtlLang
                                      ? const EdgeInsets.only(
                                          right: 0.0, left: 16.0)
                                      : const EdgeInsets.only(
                                          right: 12.0, left: 8.0)
                                  : globals.isRtlLang
                                      ? const EdgeInsets.only(
                                          right: 0.0, left: 16.0)
                                      : const EdgeInsets.only(
                                          right: 12.0, left: 0.0),
                              child: Image.asset(
                                selectedItem!.flagUri!,
                                width: widget.flagSize,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    Flexible(
                      fit: widget.alignLeft ? FlexFit.tight : FlexFit.loose,
                      child: Text(
                        widget.showOnlyCountryWhenClosed
                            ? selectedItem!.toCountryStringOnly()
                            : selectedItem.toString(),
                        style: TextStyle(
                            fontSize: AppDimen.text_size_16,
                            fontFamily: AppFont.font,
                            fontWeight: FontWeight.w500,
                            color: AppColors.PRIMARY_COLOR_DARK_TEXT_COLOR),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    )
                  ],
                ),
              );
            }
          ),
        )
      : InkWell(
          onTap: widget.showDialog ? _showSelectionDialog : () {},
          child: Text(
            widget.showOnlyCountryWhenClosed
                ? selectedItem!.toCountryStringOnly()
                : selectedItem.toString(),
            style: TextStyle(
                fontSize: AppDimen.text_size_18, fontWeight: FontWeight.normal),
          ),
        );

  @override
  initState() {
    if (widget.initialSelection != null) {
      selectedItem = elements.firstWhere(
          (e) =>
              (e.code!.toUpperCase() ==
                  widget.initialSelection?.toUpperCase()) ||
              (e.dialCode == widget.initialSelection.toString()),
          orElse: () => elements[0]);
      widget.selected_code = selectedItem!.dialCode!;

      globals.DialCode = widget.selected_code;
    } else {
      selectedItem = elements[0];
    }

    updateCountry();
    super.initState();
  }

  void _showSelectionDialog() {
    Get.dialog(
      Obx(
        () {
          return globals.isAutoThemeUpdated.value != null ? SelectionDialog(
            elements,
            favoriteElements,
            showCountryOnly: widget.showCountryOnly,
            emptySearchBuilder: widget.emptySearchBuilder,
            searchDecoration: widget.searchDecoration,
            searchStyle: widget.searchStyle,
            showFlag: widget.showFlag,
            toppadding: 20,
            height: 50,
          ) : SizedBox.shrink();
        }
      )
    ).then((e) {
      if (e != null) {
        selectedItem = e;
        globals.DialCode = selectedItem?.dialCode ?? globals.DialCode;
        globals.CountryCode = selectedItem?.code ?? globals.CountryCode;
        globals.addressUpdateController.value = true;
        _publishSelection(e);
      }
    });
  }

  void _publishSelection(CountryCode e) {
    if (widget.onChanged != null) {
      widget.onChanged!(e);
    }
  }

  void updateCountry() {
    globals.addressUpdateController.stream.listen((data) {
      controller.change(rxVariable: globals.rxExistController, value: false);
        if (globals.CountryCode != null) {
          selectedItem = elements.firstWhere(
              (e) =>
                  (e.code!.toUpperCase() ==
                      globals.CountryCode.toUpperCase()) ||
                  (e.dialCode == globals.CountryCode.toString()),
              orElse: () => elements[0]);
          widget.selected_code = selectedItem!.dialCode!;
          globals.DialCode = widget.selected_code;
        } else {
          selectedItem = elements[0];
        }
    });
  }
}