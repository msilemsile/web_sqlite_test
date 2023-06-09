import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///展示透明页面
class TransparentPage {
  static void push(BuildContext context, Widget widget) {
    Navigator.of(context).push(TransparentPageRoute(builder: (_) {
      return widget;
    }, settings: const RouteSettings()));
  }
}

///透明路由
class TransparentPageRoute extends PageRoute<void> {
  TransparentPageRoute({
    required this.builder,
    required RouteSettings settings,
  })  : super(settings: settings, fullscreenDialog: false);

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final result = builder(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: result,
      ),
    );
  }
}
