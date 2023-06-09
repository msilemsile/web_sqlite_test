import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/common/page/BasePopCallbackPage.dart';
import 'package:flutter_app/common/route/TransparentPageRoute.dart';

import 'LoadingWidget.dart';


///加载页面（A+B -> A+{loading}+B）
class PageLoading {
  Map<ModalRoute, TransparentPageRoute> loadingRouterMap = HashMap();

  ///展示loading页
  static void show(BuildContext context,
      [bool canTouchClose = false, bool canBackClose = true]) {
    ModalRoute<Object?>? currentPageRoute = ModalRoute.of(context);
    if (currentPageRoute == null || (!currentPageRoute.isCurrent)) {
      return;
    }
    bool containsKey = _instance.loadingRouterMap.containsKey(currentPageRoute);
    if (!containsKey) {
      TransparentPageRoute loadingRouter = TransparentPageRoute(
          builder: (_) {
            return BasePopCallbackPage(
              touchPopCallback: canTouchClose
                  ? (_) {
                      hide(context);
                    }
                  : (_) {},
              backPopCallback: canBackClose
                  ? (_) {
                      hide(context);
                    }
                  : (_) {},
              child: const Center(
                child: LoadingWidget(),
              ),
            );
          },
          settings: const RouteSettings());
      Navigator.of(context).push(loadingRouter);
      _instance.loadingRouterMap.addAll({currentPageRoute: loadingRouter});
    }
  }

  ///隐藏loading页
  static void hide(BuildContext context) {
    ModalRoute<Object?>? currentPageRoute = ModalRoute.of(context);
    bool containsKey = _instance.loadingRouterMap.containsKey(currentPageRoute);
    if (containsKey) {
      TransparentPageRoute? loadingRouter =
          _instance.loadingRouterMap[currentPageRoute];
      Navigator.of(context).removeRoute(loadingRouter as Route);
      _instance.loadingRouterMap.remove(currentPageRoute);
    }
  }

  static final PageLoading _instance = PageLoading._internal();

  PageLoading._internal();

  static PageLoading getInstance() {
    return _instance;
  }
}
