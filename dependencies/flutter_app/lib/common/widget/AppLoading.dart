import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/AppManager.dart';
import 'LoadingWidget.dart';

///app全局loading
class AppLoading {
  static OverlayEntry? _loadingOverLayEntry;
  static bool isShowing = false;

  ///展示loading
  static void show([bool canTouchOutSide = false]) {
    if (isShowing) {
      return;
    }
    _loadingOverLayEntry ??= OverlayEntry(builder: (context) {
        return Listener(
          behavior: canTouchOutSide
              ? HitTestBehavior.translucent
              : HitTestBehavior.opaque,
          child: const Center(
            child: LoadingWidget(),
          ),
        );
      });
    AppManager.getInstance().getOverlay()?.insert(_loadingOverLayEntry!);
    isShowing = true;
  }

  ///取消loading
  static void hide() {
    if (_loadingOverLayEntry == null) {
      return;
    }
    if (!isShowing) {
      return;
    }
    _loadingOverLayEntry?.remove();
    isShowing = false;
  }
}
