import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/theme/ThemeProvider.dart';
import 'package:flutter_app/theme/res/ColorsKey.dart';
import 'package:flutter_app/theme/res/ShapeRes.dart';

///Toast
class Toast {
  static const int lengthShort = 0;
  static const int lengthLong = 1;

  ///展示toast
  static void show(BuildContext context, String text,
      [int length = lengthShort, double offsetY = -1]) {
    OverlayEntry toastOverLayEntry = OverlayEntry(builder: (context) {
      return _ToastWidget(
        text: text,
        offsetY: offsetY,
      );
    });
    Overlay.of(context).insert(toastOverLayEntry);
    _startToastDismissTask(toastOverLayEntry, length);
  }

  ///执行toast消失任务
  static void _startToastDismissTask(
      OverlayEntry toastOverLayEntry, int length) {
    Duration duration;
    if (length > 0) {
      duration = const Duration(seconds: 4);
    } else {
      duration = const Duration(seconds: 2);
    }
    Timer(duration, () {
      toastOverLayEntry.remove();
    });
  }
}

class _ToastWidget extends StatelessWidget {
  final String text;
  final double offsetY;
  final double offsetYPercent = 0.8;

  const _ToastWidget({required this.text, this.offsetY = -1});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(top: statusBarHeight),
      child: Stack(
        children: [
          Positioned(
            width: width,
            top: offsetY >= 0
                ? offsetY
                : ((height - statusBarHeight) * offsetYPercent),
            child: Center(
              child: RectangleShape(
                cornerAll: 3,
                solidColor: ThemeProvider.getColor(context, ColorsKey.bgDarkMode),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: DefaultTextStyle(
                    style: ThemeProvider.getPlatformTextStyle(context),
                    child: Text(
                      text,
                      style: TextStyle(color: ThemeProvider.getColor(context, ColorsKey.bgLightMode)),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
