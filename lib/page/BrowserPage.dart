import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/page/HomePage.dart';
import 'package:web_sqlite_test/utils/StorageHelper.dart';
import 'package:web_sqlite_test/webview/WebViewWrapper.dart';

class BrowserPage extends StatefulWidget {
  final String initUrl;
  final OnTabPageCreateListener onTabPageCreateListener;

  const BrowserPage(
      {super.key,
      required this.onTabPageCreateListener,
      required this.initUrl});

  @override
  State<StatefulWidget> createState() {
    return _BrowserPageState();
  }
}

class _BrowserPageState extends State<BrowserPage>
    with AutomaticKeepAliveClientMixin, HomeTabTapController {

  WebViewWrapperController? webViewWrapperController;
  TextEditingController urlEditingController = TextEditingController();
  FocusNode urlEditFocusNode = FocusNode();
  final ValueNotifier<bool> _showClearTextValue = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.onTabPageCreateListener(this);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        buildTopBrowserWidget(),
        Expanded(child: WebViewWrapper(
          wrapperListener: (WebViewWrapperController controller) {
            webViewWrapperController = controller;
            urlEditingController.text = widget.initUrl;
            loadWebUrl();
          },
        )),
      ],
    );
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
                  onTap: () => webGoBack(),
                  child: SizedBox(
                    width: 40,
                    height: 49,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Image.asset("images/icon_arrow_left.png"),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => webReload(),
                  child: SizedBox(
                    width: 40,
                    height: 49,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
                      child: Image.asset("images/icon_refresh_web.png"),
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
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
                            child: TextField(
                              onSubmitted: (_) {
                                loadWebUrl();
                              },
                              onChanged: (urlEditValue) {
                                if (urlEditValue.isEmpty) {
                                  if (_showClearTextValue.value) {
                                    _showClearTextValue.value = false;
                                  }
                                } else {
                                  if (!_showClearTextValue.value) {
                                    _showClearTextValue.value = true;
                                  }
                                }
                              },
                              controller: urlEditingController,
                              focusNode: urlEditFocusNode,
                              decoration: const InputDecoration(
                                  hintText: "输入浏览地址", border: InputBorder.none),
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
      AppToast.show("地址不能为空");
      return;
    }

    ///判断是否是加载home主页
    if (urlText.compareTo("home") == 0) {
      loadHomeUrl();
    } else {
      if (!urlText.startsWith("file:")) {
        if (!urlText.startsWith("http")) {
          urlText = "http://$urlText";
        }
      }
      webViewWrapperController?.loadUrl(urlText);
    }
    urlEditingController.text = "";
    _showClearTextValue.value = false;
    urlEditFocusNode.unfocus();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  onTabDoubleTap() {
    webReload();
  }

  @override
  onTabLongTap() {
    loadHomeUrl();
  }

  @override
  onTabTap(bool isChangedTab) {
    if (isChangedTab) {
      return;
    }
  }

  void loadHomeUrl() {
    String homeWebFilePath = StorageHelper.getHomeWebAssetKey();
    webViewWrapperController?.loadAsset(homeWebFilePath);
  }

  void webReload() {
    AppToast.show("已重新加载当前页");
    webViewWrapperController?.reload();
  }

  void webGoBack() async {
    bool? canGoBack = await webViewWrapperController?.canGoBack();
    if (canGoBack != null && canGoBack) {
      webViewWrapperController?.goBack();
    }
  }

  @override
  Future<bool> canGoBack() async {
    bool? canGoBack = await webViewWrapperController?.canGoBack();
    if (canGoBack != null && canGoBack) {
      webViewWrapperController?.goBack();
      return false;
    }
    return true;
  }
}
