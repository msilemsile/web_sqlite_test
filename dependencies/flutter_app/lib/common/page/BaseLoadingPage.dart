import 'package:flutter/material.dart';
import 'package:flutter_app/common/page/BasePage.dart';

import '../widget/LoadingWidget.dart';

///居中loading页
class BaseLoadingPage extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool? fullScreen;
  final Color? statusBarColor;
  final Color? textColor;
  final bool initLoading;

  const BaseLoadingPage({
    super.key,
    required this.child,
    this.textColor,
    this.backgroundColor,
    this.fullScreen,
    this.statusBarColor,
    this.initLoading = false,
  });

  @override
  State<StatefulWidget> createState() {
    return BaseLoadingPageState();
  }

  static BaseLoadingPageState? of(BuildContext context) {
    BaseLoadingPageState? loadingPageState =
        context.findAncestorStateOfType<BaseLoadingPageState>();
    return loadingPageState;
  }
}

class BaseLoadingPageState extends State<BaseLoadingPage> {
  bool _hasLoading = false;

  @override
  Widget build(BuildContext context) {
    return BasePage(
      textColor: widget.textColor,
      statusBarColor: widget.statusBarColor,
      fullScreen: widget.fullScreen,
      backgroundColor: widget.backgroundColor,
      child: Stack(
        children: [
          widget.child,
          Visibility(
              visible: _hasLoading | widget.initLoading,
              child: const Center(child: LoadingWidget()))
        ],
      ),
    );
  }

  void showLoading() {
    setState(() {
      _hasLoading = true;
    });
  }

  void hideLoading() {
    setState(() {
      _hasLoading = false;
    });
  }
}
