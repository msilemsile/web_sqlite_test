import 'package:flutter/material.dart';
import 'package:flutter_app/common/page/BasePopCallbackPage.dart';
import 'package:flutter_app/common/widget/Toast.dart';

import '../route/TransparentPageRoute.dart';

///popup window
class PopupWindow {
  late TransparentPageRoute _popRoute;
  late ModalRoute _currentPageRoute;

  ///展示popup window
  void show(BuildContext context, Widget popWidget,
      {double offsetX = 0, double offsetY = 0}) {
    var renderObject = context.findRenderObject();
    if (renderObject == null) {
      Toast.show(context, "获取弹窗位置失败!");
    } else {
      RenderBox renderBox = renderObject as RenderBox;
      Size size = renderBox.size;
      Offset offset = renderBox.localToGlobal(Offset.zero);
      _popRoute = TransparentPageRoute(
          builder: (_) {
            return BasePopCallbackPage(
              touchPopCallback: (_) {
                hide(context);
              },
              backPopCallback: (_) {
                hide(context);
              },
              child: Stack(
                children: [
                  Positioned(
                    left: offset.dx + offsetX,
                    top: offset.dy + size.height + offsetY,
                    child: popWidget,
                  )
                ],
              ),
            );
          },
          settings: const RouteSettings());
      _currentPageRoute = ModalRoute.of(context)!;
      Navigator.of(context).push(_popRoute);
    }
  }

  ///隐藏popup window
  void hide(BuildContext context) {
    ModalRoute<Object?>? currentPageRoute = ModalRoute.of(context);
    if (_currentPageRoute == currentPageRoute) {
      Navigator.of(context).removeRoute(_popRoute);
    }
  }
}
