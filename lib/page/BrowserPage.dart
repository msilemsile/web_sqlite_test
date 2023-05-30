import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/common/widget/SpaceWidget.dart';
import 'package:flutter_app/common/widget/Toast.dart';
import 'package:flutter_app/theme/ThemeProvider.dart';
import 'package:flutter_app/theme/res/ShapeRes.dart';
import 'package:web_sqlite_test/page/HomePage.dart';
import 'package:web_sqlite_test/webview/WebViewWrapper.dart';

class BrowserPage extends StatefulWidget {
  final OnTabPageCreateListener onTabPageCreateListener;

  const BrowserPage({super.key, required this.onTabPageCreateListener});

  @override
  State<StatefulWidget> createState() {
    return _BrowserPageState();
  }
}

class _BrowserPageState extends State<BrowserPage>
    with
        AutomaticKeepAliveClientMixin,
        HomeTabTapController,
        SingleTickerProviderStateMixin {
  WebViewWrapperController? webViewWrapperController;
  TextEditingController urlEditingController = TextEditingController();
  FocusNode urlEditFocusNode = FocusNode();
  final ValueNotifier<bool> _showHintTextValue = ValueNotifier(true);
  final ValueNotifier<bool> _showClearTextValue = ValueNotifier(false);
  late AnimationController _urlInputAnimController;
  late Tween<Offset> _urlInputAnimTween;

  @override
  void initState() {
    super.initState();
    _urlInputAnimTween =
        Tween(begin: const Offset(0, -1), end: const Offset(0, 0));
    _urlInputAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.onTabPageCreateListener(this);
    });
  }

  @override
  void dispose() {
    _urlInputAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
        child: Listener(
          onPointerDown: (_) {
            if (_urlInputAnimController.isCompleted) {
              _urlInputAnimController.reverse();
              urlEditFocusNode.unfocus();
            }
          },
          child: Stack(
            children: [
              WebViewWrapper(
                initUrl: "https://www.baidu.com",
                wrapperListener: (WebViewWrapperController controller) {
                  webViewWrapperController = controller;
                },
              ),
              SlideTransition(
                position: _urlInputAnimController.drive(_urlInputAnimTween),
                child: buildTopBrowserWidget(),
              ),
            ],
          ),
        ),
        onWillPop: () async {
          bool? canGoBack = await webViewWrapperController?.canGoBack();
          if (canGoBack != null && canGoBack) {
            webViewWrapperController?.goBack();
            return Future.value(false);
          }
          return Future.value(true);
        });
  }

  Widget buildTopBrowserWidget() {
    return RectangleShape(
        solidColor: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SpaceWidget.createHeightSpace(1, spaceColor: Colors.grey),
            Row(
              children: [
                GestureDetector(
                  onTap: () => loadHomeUrl(),
                  child: SizedBox(
                    width: 50,
                    height: 49,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset("images/icon_home.png"),
                    ),
                  ),
                ),
                Expanded(
                    child: SizedBox(
                  height: 50,
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ValueListenableBuilder(
                              valueListenable: _showHintTextValue,
                              builder: (buildContext, showHintText, child) {
                                return Visibility(
                                    visible: showHintText,
                                    child: const Text("输入浏览地址"));
                              }),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
                            child: TextField(
                              onSubmitted: (_) {
                                loadWebUrl();
                              },
                              onChanged: (urlEditValue) {
                                if (urlEditValue.isEmpty) {
                                  if (!_showHintTextValue.value) {
                                    _showHintTextValue.value = true;
                                  }
                                  if (_showClearTextValue.value) {
                                    _showClearTextValue.value = false;
                                  }
                                } else {
                                  if (_showHintTextValue.value) {
                                    _showHintTextValue.value = false;
                                  }
                                  if (!_showClearTextValue.value) {
                                    _showClearTextValue.value = true;
                                  }
                                }
                              },
                              controller: urlEditingController,
                              focusNode: urlEditFocusNode,
                              decoration: null,
                              keyboardType: TextInputType.url,
                              cursorColor: const Color(0xff1E90FF),
                              style: ThemeProvider.getDefTextStyle(
                                  defColor: const Color(0xff1E90FF)),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ValueListenableBuilder(
                              valueListenable: _showClearTextValue,
                              builder: (buildContext, showClearText, child) {
                                return Visibility(
                                  visible: showClearText,
                                  child: GestureDetector(
                                    onTap: () {
                                      urlEditingController.text = "";
                                      _showClearTextValue.value = false;
                                      _showHintTextValue.value = true;
                                    },
                                    child: Image.asset(
                                        width: 25,
                                        height: 25,
                                        "images/icon_circle_close.png"),
                                  ),
                                );
                              }),
                        )
                      ],
                    ),
                  ),
                )),
                GestureDetector(
                  onTap: () => loadWebUrl(),
                  child: SizedBox(
                    width: 50,
                    height: 49,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset("images/icon_arrow_right.png"),
                    ),
                  ),
                )
              ],
            ),
            SpaceWidget.createHeightSpace(1, spaceColor: Colors.grey),
          ],
        ));
  }

  void loadWebUrl() {
    String urlText = urlEditingController.text;
    if (urlText.isEmpty) {
      Toast.show(context, "地址不能为空");
      return;
    }
    if (!urlText.startsWith("file:")) {
      if (!urlText.startsWith("http")) {
        urlText = "http://$urlText";
      }
    }
    webViewWrapperController?.loadUrl(urlText);
    urlEditingController.text = "";
    _showHintTextValue.value = true;
    _showClearTextValue.value = false;
    _urlInputAnimController.reverse();
    urlEditFocusNode.unfocus();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  onTabDoubleTap() async {
    bool? canGoBack = await webViewWrapperController?.canGoBack();
    if (canGoBack != null && canGoBack) {
      webViewWrapperController?.goBack();
    }
  }

  @override
  onTabLongTap() {
    Toast.show(context, "已重新加载当前页");
    webViewWrapperController?.reload();
  }

  @override
  onTabTap(bool isChangedTab) {
    if (isChangedTab) {
      return;
    }
    if (_urlInputAnimController.isAnimating) {
      return;
    }
    if (_urlInputAnimController.isCompleted) {
      _urlInputAnimController.reverse();
      urlEditFocusNode.unfocus();
    } else {
      _urlInputAnimController.forward();
      urlEditFocusNode.requestFocus();
    }
  }

  void loadHomeUrl() {}
}
