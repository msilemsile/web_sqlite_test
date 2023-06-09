import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/theme/ThemeProvider.dart';
import 'package:flutter_app/theme/res/ColorsKey.dart';

///自定义基础界面 适配暗色模式状态栏
class BasePage extends StatelessWidget {
  final Widget child;
  final Color? textColor;
  final Color? backgroundColor;
  final bool? fullScreen;
  final Color? statusBarColor;

  const BasePage({
    super.key,
    required this.child,
    this.textColor,
    this.backgroundColor,
    this.fullScreen,
    this.statusBarColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget realChild = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ??
            ThemeProvider.getColor(context, ColorsKey.backgroundColor),
      ),
      child: child,
    );
    if (fullScreen == null || !fullScreen!) {
      double titlePadding = MediaQuery.of(context).padding.top;
      if (titlePadding > 0) {
        realChild = Padding(
          padding: EdgeInsets.only(top: titlePadding),
          child: realChild,
        );
      }
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: ThemeProvider.getSystemUiStyle(context, statusBarColor),
        child: DefaultTextStyle(
            style: ThemeProvider.getPlatformTextStyle(context,
                defColor: textColor),
            child: realChild));
  }
}
