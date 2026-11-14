library pin_input_text_field;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_dimen.dart';
import 'package:app_name/resources/values/app_fonts.dart';
import 'package:rxdart/subjects.dart' show BehaviorSubject;

class PinInputTextField extends StatefulWidget {
  final int pinLength;
  final ValueChanged<String>? onSubmit;
  final List<TextInputFormatter> inputFormatters;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final bool autoFocus;
  final bool emptypin;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final double gapSpace;
  final List<double>? gapSpaces;
  final double lineHeight;
  final TextStyle? textStyle;
  final String?  hintText;



  PinInputTextField({
    Key? key,
    this.pinLength = 6,
    this.onSubmit,

    List<TextInputFormatter>? inputFormatter,
    this.keyboardType = TextInputType.phone,
    this.controller,
    this.focusNode,
    this.autoFocus = false,
    this.textInputAction = TextInputAction.done,
    this.enabled = true,
    this.emptypin = false,
    this.onChanged,
    this. textStyle,
    this.hintText,
    this.gapSpace = 26.0,
    this.gapSpaces,
    this.lineHeight = 20.0,
  })  :
        assert(pinLength != null && pinLength > 0),
        assert(hintText == null ||
            hintText.length == pinLength),
        assert(
        (
            pinLength - 1 ==
                (gapSpaces?.length ?? (pinLength - 1))) ),
        inputFormatters = <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(pinLength)
        ],
        super(key: key);

  @override
  State createState() {
    return _PinInputTextFieldState();
  }
}

class _PinInputTextFieldState extends State<PinInputTextField> {
  RxString _text = ''.obs;
  TextEditingController? _controller;
  TextEditingController get _effectiveController =>
      widget.controller! ?? _controller!;

  void _pinChanged() {
      _updateText();
  }

  void _updateText() {

    if (_effectiveController.text.runes.length > widget.pinLength) {
      _text.value = String.fromCharCodes(
          _effectiveController.text.runes.take(widget.pinLength));
    } else {
      _text.value = _effectiveController.text;
    }
    _text.value=_text.value;
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
    }
    _effectiveController.addListener(_pinChanged);
    _updateText();
  }

  @override
  void dispose() {
    _text.close();
    _effectiveController.removeListener(_pinChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(PinInputTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller == null && oldWidget.controller != null) {
      oldWidget.controller?.removeListener(_pinChanged);
      _controller = TextEditingController.fromValue(oldWidget.controller?.value);
      _controller?.addListener(_pinChanged);
    } else if (widget.controller != null && oldWidget.controller == null) {
      _controller?.removeListener(_pinChanged);
      _controller = null;
      widget.controller?.addListener(_pinChanged);
      if (_text != widget.controller?.text) {
        _pinChanged();
      }
    } else if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_pinChanged);
      widget.controller?.addListener(_pinChanged);
    }
    if (oldWidget.pinLength > widget.pinLength &&
        _text.value.runes.length > widget.pinLength) {
        _text.value = _text.value.substring(0, widget.pinLength);
        _effectiveController.text = _text.value;
        _effectiveController.selection =
            TextSelection.collapsed(offset: _text.value.runes.length);
        _text.value=_text.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    clearPin();
    return Obx((){
        return CustomPaint(
          foregroundPainter: _PinPaint(
              text: _text.value,
              pinLength: widget.pinLength,
              lineHeight: widget.lineHeight,
              hintText: widget.hintText,
              ListSpaces:widget.gapSpaces,
              gapSpace: widget.gapSpace,
              themeData: Theme.of(context)),
          child: TextField(
            controller: _effectiveController,
            style: TextStyle(
              color: Colors.transparent,
              fontSize: 1,
            ),
            cursorColor: Colors.transparent,
            cursorWidth: 0.0,
            autocorrect: false,
            textAlign: TextAlign.center,
            enableInteractiveSelection: false,
            maxLength: widget.pinLength,
            onSubmitted: widget.onSubmit,
            keyboardType: TextInputType.number,
            inputFormatters: widget.inputFormatters,
            focusNode: widget.focusNode,
            autofocus: widget.autoFocus,
            textInputAction: widget.textInputAction,
            obscureText: true,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
            enabled: widget.enabled,
          ),
        );
      }
    );
  }

  void clearPin() {
    if(widget.emptypin)
      _effectiveController.text="";

  }
}

class _PinPaint extends CustomPainter {
  final String text;
  final int pinLength;
  final ThemeData? themeData;
  final double? lineHeight;
  final String?  hintText;
  final double? gapSpace;
  final List<double>? ListSpaces;

  _PinPaint({
    required this.text,
    required this.pinLength,
    this.lineHeight,
    this.hintText,
    this.ListSpaces,
    this.gapSpace,
    this.themeData,
  }) ;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) =>
      !(oldDelegate is _PinPaint && oldDelegate.text == this.text);
  _drawUnderLine(Canvas canvas, Size size) {
    Paint underlinePaint = Paint()
      ..color = AppColors.PRIMARY_LIGHT_COLOR
      ..strokeWidth = lineHeight!
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    var startX = 0.0;
    var startY = 0.0;
    double gapTotalLength =
        ListSpaces?.reduce((a, b) => a + b) ?? (pinLength - 1) * gapSpace!;
    List<double> gapSpaces =
        ListSpaces ?? List.filled(pinLength - 1, gapSpace!);
    double singleWidth = (size.width - gapTotalLength) / pinLength;

    Radius radius= const Radius.circular(3.0);

    for (int i = 0; i < pinLength; i++) {
      if (i < text.length ) {
        underlinePaint.color = AppColors.BLACK_TEXT_COLOR;
      }  else {
        underlinePaint.color = AppColors.PRIMARY_LIGHT_COLOR;
      }

      RRect rRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            startX,
            -7,
            startX + singleWidth+5,
            singleWidth-2,
          ),
          radius);
      
      


      canvas.drawPath(Path()..addRRect(rRect),
          Paint()
            ..color= AppColors.PRIMARY_LIGHT_COLOR
            ..maskFilter = MaskFilter.blur(BlurStyle.solid,  0.57735 + 0.2));


      startX += singleWidth + (i == pinLength - 1 ? 0 : gapSpaces[i]);
    }
    var index = 0;
    startX = 0.0;

    text.runes.forEach((rune) {
      String code;
      code = String.fromCharCode(rune);
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          style: TextStyle(
              color: AppColors.BLACK_TEXT_COLOR,
              fontFamily: AppFont.font,
              fontSize: AppDimen.text_size_24,
              fontWeight: FontWeight.w600
          ),
          text: code,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      startY =(singleWidth - textPainter.height)/2;

      startX = singleWidth * index +
          singleWidth / 2 -
          textPainter.width / 2 +
          _sumList(gapSpaces.take(index))+3;
      textPainter.paint(canvas, Offset(startX, startY-3.5));
      index++;
    });

    if (hintText != null) {
      hintText!.substring(index).runes.forEach((rune) {
        String code = String.fromCharCode(rune);
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            style: TextStyle(
                color: AppColors.PLACEHOLDER_TEXT_COLOR,
                fontFamily: AppFont.font,
                fontSize: AppDimen.text_size_24,
                fontWeight: FontWeight.w400
            ),
            text: code,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        startY =(singleWidth - textPainter.height)/2;
        startX = singleWidth * index +
            singleWidth / 2 -
            textPainter.width / 2 +
            _sumList(gapSpaces.take(index))+3;
        textPainter.paint(canvas, Offset(startX, startY-3.5));
        index++;
      });
    }
  }

  T _sumList<T extends dynamic>(Iterable<T> list) {
    T sum = 0 as T;
    list.forEach((n) => sum += n);
    return sum;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawUnderLine(canvas, size);
  }
}