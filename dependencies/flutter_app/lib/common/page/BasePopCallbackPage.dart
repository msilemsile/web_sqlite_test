import 'package:flutter/material.dart';

import 'BasePage.dart';

typedef OnPageWillPopCallback = void Function(BuildContext context);

///监听返回WillPopPage(touchPopCallback点击透明区域回调 backPopCallback是否点击返回按键回调)
class BasePopCallbackPage extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool? fullScreen;
  final Color? statusBarColor;
  final Color? textColor;
  final OnPageWillPopCallback touchPopCallback;
  final OnPageWillPopCallback backPopCallback;

  const BasePopCallbackPage({
    super.key,
    required this.child,
    this.backgroundColor = Colors.transparent,
    this.fullScreen = true,
    this.statusBarColor,
    this.textColor,
    required this.touchPopCallback,
    required this.backPopCallback,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        backPopCallback(context);
        return Future.value(false);
      },
      child: BasePage(
        textColor: textColor,
        fullScreen: fullScreen,
        backgroundColor: backgroundColor,
        statusBarColor: statusBarColor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: child,
          onTap: () {
            touchPopCallback(context);
          },
        ),
      ),
    );
  }
}
