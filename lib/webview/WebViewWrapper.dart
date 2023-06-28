import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/common/log/Log.dart';
import 'package:web_sqlite_test/router/RouterManager.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Import for Windows features.
import 'package:webview_windows/webview_windows.dart' as windows;

typedef WebViewWrapperListener = Function(
    WebViewWrapperController wrapperController);

class WebViewWrapper extends StatefulWidget {
  final WebViewWrapperListener wrapperListener;

  const WebViewWrapper({super.key, required this.wrapperListener});

  @override
  State<StatefulWidget> createState() {
    return _WebViewWrapperState();
  }
}

class _WebViewWrapperState extends State<WebViewWrapper>
    with WebViewWrapperController {
  late final WebViewController _phoneWebController;
  late final windows.WebviewController _winWebController;
  late bool _winWebCanGoBack;
  final ValueNotifier<double> _progressBarValue = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _phoneWebController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel("websql",
            onMessageReceived: (JavaScriptMessage javaScriptMessage) async {
          Log.message(
              "_phoneWebController javascript ${javaScriptMessage.message}");
          RouterManager.route(javaScriptMessage.message,
              callback: (routerResult, [routerId]) {
            routerId ??= "0";
            routerResult = base64Encode(Uint8List.fromList(routerResult.codeUnits));
            _phoneWebController.runJavaScript(
                "onWebSQLCallback('$routerResult','$routerId')");
            Log.message("_phoneWebController WebSQLRouter.route $routerResult");
          });
        })
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (progress == 100) {
                progress = 0;
              }
              _progressBarValue.value = progress.toDouble();
              Log.message('WebView is loading (progress : $progress%)');
            },
            onPageStarted: (String url) {
              Log.message('Page started loading: $url');
            },
            onPageFinished: (String url) {
              Log.message('Page finished loading: $url');
            },
            onNavigationRequest: (NavigationRequest request) {
              if (!request.url.startsWith('http')) {
                return NavigationDecision.prevent;
              }
              Log.message('allowing navigation to ${request.url}');
              return NavigationDecision.navigate;
            },
          ),
        );
    } else if (Platform.isWindows) {
      () async {
        _winWebController = windows.WebviewController();
        _winWebController.loadingState.listen((event) {});
        _winWebController.historyChanged.listen((event) {
          _winWebCanGoBack = event.canGoBack;
          Log.message("_winWebController historyChange $event");
        });
        _winWebController.webMessage.listen((event) {
          Log.message("_winWebController javascript $event");
        });
        await _winWebController.initialize();
        if (!mounted) return;
        setState(() {});
      }();
    }
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.wrapperListener(this);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return Stack(
        children: [
          WebViewWidget(controller: _phoneWebController),
          ValueListenableBuilder(
              valueListenable: _progressBarValue,
              builder: (BuildContext context, double progress, _) {
                return LinearProgressIndicator(
                  minHeight: 1,
                  backgroundColor: Colors.white,
                  value: progress,
                  color: const Color(0xff1E90FF),
                );
              })
        ],
      );
    } else if (Platform.isWindows) {
      return windows.Webview(_winWebController);
    }
    return buildUnSupportPlatform();
  }

  ///不支持的平台
  Widget buildUnSupportPlatform() {
    return const Center(
      child: Text(
        "WebView暂不支持该平台",
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  @override
  void loadUrl(String url) {
    if (Platform.isAndroid || Platform.isIOS) {
      _phoneWebController.loadRequest(Uri.parse(url));
    } else if (Platform.isWindows) {
      _winWebController.loadUrl(url);
    }
  }

  @override
  Future<bool> canGoBack() {
    if (Platform.isAndroid || Platform.isIOS) {
      return _phoneWebController.canGoBack();
    } else if (Platform.isWindows) {
      return Future.value(_winWebCanGoBack);
    }
    return Future.value(false);
  }

  @override
  void goBack() {
    if (Platform.isAndroid || Platform.isIOS) {
      _phoneWebController.goBack();
    } else if (Platform.isWindows) {
      _winWebController.goBack();
    }
  }

  @override
  void reload() {
    if (Platform.isAndroid || Platform.isIOS) {
      _phoneWebController.reload();
    } else if (Platform.isWindows) {
      _winWebController.reload();
    }
  }

  @override
  void loadFile(String filePath) {
    if (Platform.isAndroid || Platform.isIOS) {
      _phoneWebController.loadFile(filePath);
    } else if (Platform.isWindows) {
      _winWebController.loadUrl(filePath);
    }
  }

  @override
  void loadAsset(String filePath) {
    if (Platform.isAndroid || Platform.isIOS) {
      _phoneWebController.loadFlutterAsset(filePath);
    } else if (Platform.isWindows) {
      _winWebController.loadUrl(filePath);
    }
  }
}

mixin WebViewWrapperController {

  void loadAsset(String filePath);

  void loadFile(String filePath);

  void loadUrl(String url);

  Future<bool> canGoBack();

  void goBack();

  void reload();
}
