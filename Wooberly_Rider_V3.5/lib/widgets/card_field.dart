// import 'dart:developer' as dev;
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:app_name/resources/values/app_colors.dart';
// import 'package:app_name/utils/globals.dart' as globals;
//
// class CardField extends StatefulWidget {
//   const CardField({
//     this.onCardChanged,
//     Key? key,
//     this.onFocus,
//     this.decoration,
//     this.enablePostalCode = false,
//     this.countryCode,
//     this.style,
//     this.autofocus = false,
//     this.dangerouslyGetFullCardDetails = false,
//     this.dangerouslyUpdateFullCardDetails = false,
//     this.cursorColor,
//     this.numberHintText,
//     this.expirationHintText,
//     this.cvcHintText,
//     this.postalCodeHintText,
//     this.controller,
//     this.androidPlatformViewRenderType,
//   }) : super(key: key);
//
//   final InputDecoration? decoration;
//
//   final CardFocusCallback? onFocus;
//
//   final CardChangedCallback? onCardChanged;
//
//   final TextStyle? style;
//
//   final Color? cursorColor;
//
//   final bool enablePostalCode;
//
//   final String? countryCode;
//
//   final String? numberHintText;
//
//   final String? expirationHintText;
//
//   final String? cvcHintText;
//
//   final String? postalCodeHintText;
//
//   final bool autofocus;
//
//   final CardEditController? controller;
//
//   final bool dangerouslyGetFullCardDetails;
//
//   final bool dangerouslyUpdateFullCardDetails;
//
//   final AndroidPlatformViewRenderType? androidPlatformViewRenderType;
//
//   @override
//   _CardFieldState createState() => _CardFieldState();
// }
//
// class _CardFieldState extends State<CardField> {
//   final FocusNode _node = FocusNode(debugLabel: 'CardField', descendantsAreFocusable: false);
//   CardEditController? _fallbackContoller;
//   CardEditController get controller {
//     if (widget.controller != null) return widget.controller!;
//     _fallbackContoller ??= CardEditController();
//     return _fallbackContoller!;
//   }
//
//   @override
//   void initState() {
//     _node.addListener(updateState);
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     _node
//       ..removeListener(updateState)
//       ..dispose();
//
//     _fallbackContoller?.dispose();
//     super.dispose();
//   }
//
//   void updateState() {
//     if (mounted) {
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Builder(
//       builder: (_) {
//         final inputDecoration = effectiveDecoration(widget.decoration ?? const InputDecoration());
//         final style = effectiveCardStyle(inputDecoration);
//         final platformCardHeight = style.fontSize!.toDouble() + 31;
//         const platformMargin = const EdgeInsets.fromLTRB(12, 10, 10, 12);
//
//         final cardHeight = platformCardHeight - platformMargin.vertical;
//
//         final placeholder = CardPlaceholder(
//           number: widget.numberHintText,
//           expiration: widget.expirationHintText,
//           cvc: widget.cvcHintText,
//           postalCode: widget.postalCodeHintText,
//         );
//
//         final platform = kIsWeb
//             ? Stripe.buildWebCard(
//           controller: controller,
//           height: platformCardHeight,
//           focusNode: _node,
//           onCardChanged: widget.onCardChanged,
//           enablePostalCode: widget.enablePostalCode,
//           autofocus: widget.autofocus,
//           onFocus: widget.onFocus,
//           placeholder: placeholder,
//           style: style,
//         )
//             : CustomSingleChildLayout(
//           delegate: const _NegativeMarginLayout(margin: platformMargin),
//           child: _MethodChannelCardField(
//             constraints: const BoxConstraints(),
//             controller: controller,
//             height: platformCardHeight,
//             focusNode: _node,
//             style: style,
//             placeholder: placeholder,
//             enablePostalCode: widget.enablePostalCode,
//             countryCode: widget.countryCode,
//             dangerouslyGetFullCardDetails:
//             widget.dangerouslyGetFullCardDetails,
//             dangerouslyUpdateFullCardDetails:
//             widget.dangerouslyUpdateFullCardDetails,
//             onCardChanged: widget.onCardChanged,
//             autofocus: widget.autofocus,
//             onFocus: widget.onFocus,
//           ),
//         );
//         return Container(
//           height: 94,
//           padding: const EdgeInsetsDirectional.only(start: 20, end: 20, top: 18),
//           margin: const EdgeInsetsDirectional.only(top: 30, start: 24, end: 24),
//           decoration: BoxDecoration(
//               color: AppColors.PRIMARY_LIGHT_COLOR,
//               borderRadius: BorderRadius.all(Radius.circular(3))),
//           child: InputDecorator(
//             isFocused: _node.hasFocus,
//             decoration: inputDecoration,
//             baseStyle: widget.style,
//             child: Container(
//               color: AppColors.PRIMARY_LIGHT_COLOR,
//               height: cardHeight,
//               child: platform,
//             ),
//           ),
//         );
//       }
//     );
//   }
//
//   InputDecoration effectiveDecoration(InputDecoration decoration) {
//     final theme = Theme.of(context).inputDecorationTheme;
//     final cardDecoration = decoration ?? const InputDecoration();
//     return cardDecoration.applyDefaults(theme);
//   }
//
//   CardStyle effectiveCardStyle(InputDecoration decoration) {
//     final fontSize = widget.style?.fontSize?.toInt() ??
//         Theme.of(context).textTheme.titleMedium?.fontSize?.toInt() ??
//         kCardFieldDefaultFontSize;
//
//     final fontFamily = widget.style?.fontFamily;
//
//     return CardStyle(
//       textColor: widget.style?.color,
//       fontSize: fontSize,
//       fontFamily: fontFamily,
//       cursorColor: widget.cursorColor,
//       textErrorColor: decoration.errorStyle?.color,
//       placeholderColor: decoration.hintStyle?.color,
//     );
//   }
// }
//
// class _NegativeMarginLayout extends SingleChildLayoutDelegate {
//   const _NegativeMarginLayout({this.margin});
//
//   final EdgeInsets? margin;
//
//   @override
//   BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
//     final biggest = super.getConstraintsForChild(constraints).biggest;
//     return BoxConstraints.expand(
//       width: biggest.width + margin!.horizontal,
//       height: biggest.height + margin!.vertical,
//     );
//   }
//
//   @override
//   Offset getPositionForChild(Size size, Size childSize) {
//     return super.getPositionForChild(size, childSize) - margin!.topLeft;
//   }
//
//   @override
//   bool shouldRelayout(covariant _NegativeMarginLayout oldDelegate) {
//     return margin != oldDelegate.margin;
//   }
// }
//
// class _MethodChannelCardField extends StatefulWidget {
//   _MethodChannelCardField({
//     this.onCardChanged,
//     this.controller,
//     Key? key,
//     this.onFocus,
//     this.style,
//     this.placeholder,
//     this.enablePostalCode = false,
//     this.countryCode,
//     double? width,
//     double height = kCardFieldDefaultHeight,
//    // BoxConstraints? constraints,
//     this.focusNode,
//     this.dangerouslyGetFullCardDetails = false,
//     this.dangerouslyUpdateFullCardDetails = false,
//     this.autofocus = false, required this.constraints,
//   }):super(key: key);
//
//   final BoxConstraints constraints;
//   final CardFocusCallback? onFocus;
//   final CardChangedCallback? onCardChanged;
//   final CardStyle? style;
//   final CardPlaceholder? placeholder;
//   final bool enablePostalCode;
//   final String? countryCode;
//   final FocusNode? focusNode;
//   final bool autofocus;
//   final CardEditController? controller;
//   final bool dangerouslyGetFullCardDetails;
//   final bool dangerouslyUpdateFullCardDetails;
//
//   static const _viewType = 'flutter.stripe/card_field';
//
//   @override
//   _MethodChannelCardFieldState createState() => _MethodChannelCardFieldState();
// }
//
// class _MethodChannelCardFieldState extends State<_MethodChannelCardField>
//     with CardFieldContext {
//   MethodChannel? _methodChannel;
//
//   final _focusNode =
//       FocusNode(debugLabel: 'CardField', descendantsAreFocusable: false);
//   FocusNode get _effectiveNode => widget.focusNode ?? _focusNode;
//
//   CardStyle? _lastStyle;
//   CardStyle resolveStyle(CardStyle style) {
//     final theme = Theme.of(context);
//     final baseTextStyle = Theme.of(context).textTheme.titleMedium;
//     return CardStyle(
//       borderWidth: 0,
//       backgroundColor:  AppColors.PRIMARY_LIGHT_COLOR,
//       borderColor: Colors.transparent,
//       borderRadius: 0,
//       cursorColor: theme.primaryColor,
//       textColor: theme.primaryColor,
//       fontSize: baseTextStyle?.fontSize?.toInt() ?? kCardFieldDefaultFontSize,
//       placeholderColor:
//           theme.inputDecorationTheme.hintStyle?.color ?? theme.hintColor,
//     ).apply(style);
//   }
//
//   CardPlaceholder? _lastPlaceholder;
//   CardPlaceholder resolvePlaceholder(CardPlaceholder placeholder) =>
//       CardPlaceholder(
//         number: '1234 1234 1234 1234',
//         expiration: 'MM/YY',
//         cvc: 'CVC',
//       ).apply(placeholder);
//
//   CardEditController get controller => widget.controller!;
//
//   @override
//   void initState() {
//     attachController(controller);
//
//     if (!widget.dangerouslyUpdateFullCardDetails) {
//       if (kDebugMode &&
//           controller.details != const CardFieldInputDetails(complete: false)) {
//         dev.log('WARNING! Initial card data value has been ignored. \n'
//             '$kDebugPCIMessage');
//       }
//       WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//         updateCardDetails(
//           const CardFieldInputDetails(complete: false),
//           controller,
//         );
//       });
//     }
//
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     detachController(controller);
//     _focusNode.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Builder(
//       builder: (_) {
//         final style = resolveStyle(widget.style!);
//         final placeholder = resolvePlaceholder(widget.placeholder!);
//
//         final creationParams = <String, dynamic>{
//           'cardStyle': style.toJson(),
//           'placeholder': placeholder.toJson(),
//           'postalCodeEnabled': widget.enablePostalCode,
//           'countryCode': widget.countryCode,
//           'dangerouslyGetFullCardDetails': widget.dangerouslyGetFullCardDetails,
//           if (widget.dangerouslyUpdateFullCardDetails &&
//               controller.initalDetails != null)
//             'cardDetails': controller.initalDetails?.toJson(),
//           'autofocus': widget.autofocus,
//         };
//
//         Widget platform;
//         if (defaultTargetPlatform == TargetPlatform.android) {
//           platform = _AndroidCardField(
//             key: ValueKey(globals.isDarkTheme),
//             viewType: _MethodChannelCardField._viewType,
//             creationParams: creationParams,
//             onPlatformViewCreated: onPlatformViewCreated,
//           );
//         } else if (defaultTargetPlatform == TargetPlatform.iOS) {
//           platform = Listener(
//             onPointerDown: (_) {
//               if (!_effectiveNode.hasFocus) {
//                 _effectiveNode.requestFocus();
//               }
//             },
//             child: Focus(
//               autofocus: widget.autofocus,
//               descendantsAreFocusable: true,
//               focusNode: _effectiveNode,
//               onFocusChange: _handleFrameworkFocusChanged,
//               child: _UiKitCardField(
//                 key: ValueKey(globals.isDarkTheme),
//                 viewType: _MethodChannelCardField._viewType,
//                 creationParams: creationParams,
//                 onPlatformViewCreated: onPlatformViewCreated,
//               ),
//             ),
//           );
//         } else {
//           throw UnsupportedError('Unsupported platform view');
//         }
//         final constraints = widget.constraints ?? const BoxConstraints.expand(height: kCardFieldDefaultHeight);
//         return ConstrainedBox(
//           constraints: constraints,
//           child: platform,
//         );
//       }
//     );
//   }
//
//   @override
//   void didChangeDependencies() {
//     _lastStyle ??= resolveStyle(widget.style!);
//     final style = resolveStyle(widget.style!);
//     if (style != _lastStyle) {
//       _methodChannel?.invokeMethod('onStyleChanged', {
//         'cardStyle': style.toJson(),
//       });
//     }
//     _lastStyle = style;
//     super.didChangeDependencies();
//   }
//
//   @override
//   void didUpdateWidget(covariant _MethodChannelCardField oldWidget) {
//     if (widget.controller != oldWidget.controller) {
//       assert(!controller.hasCardField,
//           'CardEditController is already attached to a CardView');
//       detachController(oldWidget.controller!);
//       attachController(oldWidget.controller!);
//     }
//     if (widget.enablePostalCode != oldWidget.enablePostalCode) {
//       _methodChannel?.invokeMethod('onPostalCodeEnabledChanged', {
//         'postalCodeEnabled': widget.enablePostalCode,
//       });
//     }
//
//     if (widget.countryCode != oldWidget.countryCode) {
//       _methodChannel?.invokeMethod('onCountryCodeChangedEvent', {
//         'countryCode': widget.countryCode,
//       });
//     }
//     if (widget.dangerouslyGetFullCardDetails !=
//         oldWidget.dangerouslyGetFullCardDetails) {
//       _methodChannel?.invokeMethod('dangerouslyGetFullCardDetails', {
//         'dangerouslyGetFullCardDetails': widget.dangerouslyGetFullCardDetails,
//       });
//     }
//     _lastStyle ??= resolveStyle(oldWidget.style!);
//     final style = resolveStyle(widget.style!);
//     if (style != _lastStyle) {
//       _methodChannel?.invokeMethod('onStyleChanged', {
//         'cardStyle': style.toJson(),
//       });
//     }
//     _lastStyle = style;
//     final placeholder = resolvePlaceholder(widget.placeholder!);
//     if (placeholder != _lastPlaceholder) {
//       _methodChannel?.invokeMethod('onPlaceholderChanged', {
//         'placeholder': placeholder.toJson(),
//       });
//     }
//     _lastPlaceholder = placeholder;
//     super.didUpdateWidget(oldWidget);
//   }
//
//   void onPlatformViewCreated(int viewId) {
//     _focusNode.debugLabel = 'CardField(id: $viewId)';
//     _methodChannel = MethodChannel('flutter.stripe/card_field/$viewId');
//     _methodChannel?.setMethodCallHandler((call) async {
//       if (call.method == 'topFocusChange') {
//         _handlePlatformFocusChanged(call.arguments);
//       } else if (call.method == 'onCardChange') {
//         _handleCardChanged(call.arguments);
//       }
//     });
//   }
//
//   void _handleCardChanged(arguments) {
//     try {
//       final map = Map<String, dynamic>.from(arguments);
//       final details = CardFieldInputDetails.fromJson(map);
//       updateCardDetails(details, controller);
//       widget.onCardChanged?.call(details);
//     } catch (e) {
//       dev.log(
//           'An error ocurred while while parsing card arguments, this should not happen, please consider creating an issue at https://github.com/flutter-stripe/flutter_stripe/issues/new');
//       rethrow;
//     }
//   }
//
//   void _handlePlatformFocusChanged(arguments) {
//     try {
//       final map = Map<String, dynamic>.from(arguments);
//       final field = CardFieldFocusName.fromJson(map);
//       if (field.focusedField != null &&
//           WidgetsBinding.instance.focusManager.primaryFocus != _effectiveNode) {
//         _effectiveNode.requestFocus();
//       }
//       widget.onFocus?.call(field.focusedField);
//     } catch (e) {
//       dev.log(
//           'An error ocurred while while parsing card arguments, this should not happen, please consider creating an issue at https://github.com/flutter-stripe/flutter_stripe/issues/new');
//       rethrow;
//     }
//   }
//
//   void _handleFrameworkFocusChanged(bool isFocused) {
//     final methodChannel = _methodChannel;
//     if (methodChannel == null) {
//       return;
//     }
//     if (mounted) {
//     }
//     if (!isFocused) {
//       blur();
//       return;
//     }
//
//     focus();
//   }
//
//   @override
//   void blur() {
//     _methodChannel?.invokeMethod('blur');
//   }
//
//   @override
//   void clear() {
//     _methodChannel?.invokeMethod('clear');
//   }
//
//   @override
//   void focus() {
//     _methodChannel?.invokeMethod('focus');
//   }
//
//   @override
//   void dangerouslyUpdateCardDetails(CardFieldInputDetails details) {
//     assert(widget.dangerouslyUpdateFullCardDetails, kDebugPCIMessage);
//     _methodChannel?.invokeMethod('dangerouslyUpdateCardDetails', {
//       'cardDetails': details.toJson(),
//     });
//   }
// }
//
// class _AndroidCardField extends StatelessWidget {
//   const _AndroidCardField({
//     Key? key,
//     this.viewType,
//     this.creationParams,
//     this.onPlatformViewCreated,
//   }) : super(key: key);
//
//   final String? viewType;
//   final Map<String, dynamic>? creationParams;
//   final PlatformViewCreatedCallback? onPlatformViewCreated;
//
//   @override
//   Widget build(BuildContext context) {
//     return AndroidView(
//       viewType: viewType!,
//       onPlatformViewCreated: onPlatformViewCreated,
//       creationParams: creationParams,
//       creationParamsCodec: const StandardMessageCodec(),
//     );
//   }
// }
//
// class _UiKitCardField extends StatelessWidget {
//   const _UiKitCardField({
//     Key? key,
//     this.viewType,
//     this.creationParams,
//     this.onPlatformViewCreated,
//   }) : super(key: key);
//
//   final String? viewType;
//   final Map<String, dynamic>? creationParams;
//   final PlatformViewCreatedCallback? onPlatformViewCreated;
//
//   @override
//   Widget build(BuildContext context) {
//     return UiKitView(
//       viewType: viewType!,
//       creationParamsCodec: const StandardMessageCodec(),
//       creationParams: creationParams,
//       onPlatformViewCreated: onPlatformViewCreated,
//     );
//   }
// }
//
// const kCardFieldDefaultHeight = 48.0;
// const kCardFieldDefaultFontSize = 17;
// const kCardFieldDefaultTextColor = Colors.black;
// const kCardFieldDefaultFontFamily = 'Roboto';