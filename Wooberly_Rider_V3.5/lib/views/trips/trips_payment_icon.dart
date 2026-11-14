import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_name/resources/values/app_colors.dart';
import 'package:app_name/resources/values/app_images.dart';

class TripsPaymentIcon extends StatelessWidget {
  final int paymentType;

  const TripsPaymentIcon({super.key, required this.paymentType});

  static const Map<int, ({String icon, double size, bool useColor})> _config = {
    1: (icon: moneySvg, size: 20.0, useColor: true),
    2: (icon: creditCardSvg, size: 20.0, useColor: true),
    3: (icon: walletSvg, size: 20.0, useColor: true),
    4: (icon: googlePaySvg, size: 25.0, useColor: false),
    6: (icon: paypalPaymentSvg, size: 22.0, useColor: false),
  };

  @override
  Widget build(BuildContext context) {
    final data = _config[paymentType] ?? (icon: payStackSvg, size: 14.0, useColor: false);
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 5, top: 2),
      width: data.size,
      height: data.size,
      child: SvgPicture.asset(
        data.icon,
        fit: BoxFit.contain,
        colorFilter: data.useColor ? ColorFilter.mode(AppColors.PRIMARY_ICON_COLOR, BlendMode.srcIn) : null,
      ),
    );
  }
}