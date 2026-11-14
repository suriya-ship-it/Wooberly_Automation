import 'package:flutter/material.dart';

class SingleTapEvent extends StatelessWidget {
 late final Widget child;
 late final Function() onTap;

  bool singleTap = false;

  SingleTapEvent(
      {Key? key, required this.child, required this.onTap, singleTap = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: ()  {
          if (!singleTap) {
            Function.apply(onTap, []);
            singleTap = true;
            Future.delayed(const Duration(seconds: 3)).then((value) => singleTap = false);
          }
        },
        child: child);
  }
}