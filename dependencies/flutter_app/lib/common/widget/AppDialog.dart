import 'package:flutter/material.dart';
import 'package:flutter_app/common/page/BasePopCallbackPage.dart';
import 'package:flutter_app/common/route/TransparentPageRoute.dart';

import '../page/BasePage.dart';

///AppDialog
class AppDialog {
  late TransparentPageRoute _dialogRoute;
  late ModalRoute _currentPageRoute;

  ///展示dialog
  void show(BuildContext context, Widget dialogWidget,
      [bool canTouchClose = true, bool canBackClose = true, bool needBgMark = true]) {
    _dialogRoute = TransparentPageRoute(
        builder: (_) {
          return BasePopCallbackPage(
            touchPopCallback: canTouchClose
                ? (_) {
              dismiss(context);
            }
                : (_) {},
            backPopCallback: canBackClose
                ? (_) {
              dismiss(context);
            }
                : (_) {},
            child: _DialogInnerPage(
              child: dialogWidget,
              needBgMark: needBgMark,
            ),
          );
        },
        settings: const RouteSettings());
    _currentPageRoute = ModalRoute.of(context)!;
    Navigator.of(context).push(_dialogRoute);
  }

  ///隐藏dialog
  void dismiss(BuildContext context) {
    ModalRoute<Object?>? currentPageRoute = ModalRoute.of(context);
    if (_currentPageRoute == currentPageRoute) {
      Navigator.of(context).removeRoute(_dialogRoute);
    }
  }
}

///dialog Page页面展示居中位置
class _DialogInnerPage extends StatelessWidget {
  final Widget child;
  final bool needBgMark;

  const _DialogInnerPage(
      {super.key, required this.child, required this.needBgMark});

  @override
  Widget build(BuildContext context) {
    return BasePage(
        fullScreen: true,
        backgroundColor: needBgMark ? Colors.black54 : Colors.transparent,
        child: Center(
          child: child,
        ));
  }
}
