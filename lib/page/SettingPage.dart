import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/page/HomePage.dart';
import 'package:web_sqlite_test/service/LanBroadcastService.dart';
import 'package:web_sqlite_test/service/LanConnectService.dart';
import 'package:web_sqlite_test/service/WebSQLHttpServer.dart';
import 'package:web_sqlite_test/theme/AppColors.dart';
import 'package:web_sqlite_test/utils/HostHelper.dart';

class SettingPage extends StatefulWidget {
  final OnTabPageCreateListener onTabPageCreateListener;

  const SettingPage({super.key, required this.onTabPageCreateListener});

  @override
  State<StatefulWidget> createState() {
    return _SettingPageState();
  }
}

class _SettingPageState extends State<SettingPage>
    with AutomaticKeepAliveClientMixin, HomeTabTapController {
  final ValueNotifier<bool> _lanBroadcastControl = ValueNotifier(false);
  final ValueNotifier<bool> _httpDBControl = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.onTabPageCreateListener.call(this);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        buildSettingTitleWidget(),
        ValueListenableBuilder(
            valueListenable: _lanBroadcastControl,
            builder: (context, controlValue, child) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: Stack(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Text(
                          "局域网数据库互操作",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.mainColor),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                        child: Material(
                          color: Colors.transparent,
                          child: Switch(
                              value: controlValue,
                              onChanged: (newValue) async {
                                _lanBroadcastControl.value = newValue;
                                if (newValue) {
                                  HostInfo? hostInfo =
                                      await HostHelper.getInstance()
                                          .getLocalHostInfo();
                                  if (hostInfo == null) {
                                    AppToast.show("获取ip失败,请检查网络连接");
                                    _lanBroadcastControl.value = false;
                                    return;
                                  }
                                  await LanConnectService.getInstance()
                                      .bindService();
                                  await LanBroadcastService.getInstance()
                                      .startBroadcast();
                                } else {
                                  HostHelper.getInstance()
                                      .releaseLocalHostInfo();
                                  LanBroadcastService.getInstance()
                                      .stopBroadcast();
                                  LanConnectService.getInstance().destroy();
                                }
                              }),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: SpaceWidget.createHeightSpace(1,
                          spaceColor: AppColors.lineColor),
                    )
                  ],
                ),
              );
            }),
        ValueListenableBuilder(
            valueListenable: _httpDBControl,
            builder: (context, controlValue, child) {
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Stack(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: Text(
                              "http协议数据库操作",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.mainColor),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                            child: Material(
                              color: Colors.transparent,
                              child: Switch(
                                  value: controlValue,
                                  onChanged: (newValue) async {
                                    _httpDBControl.value = newValue;
                                    if (newValue) {
                                      HostInfo? hostInfo =
                                          await HostHelper.getInstance()
                                              .getLocalHostInfo();
                                      if (hostInfo == null) {
                                        AppToast.show("获取ip失败,请检查网络连接");
                                        _httpDBControl.value = false;
                                        return;
                                      }
                                      await WebSQLHttpServer.getInstance()
                                          .startServer();
                                    } else {
                                      WebSQLHttpServer.getInstance().destroy();
                                    }
                                  }),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: SpaceWidget.createHeightSpace(1,
                              spaceColor: AppColors.lineColor),
                        )
                      ],
                    ),
                  ),
                  Visibility(
                      visible: _httpDBControl.value,
                      child: SizedBox(
                        width: double.infinity,
                        height: 35,
                        child: Center(
                          child: RichText(
                              text: TextSpan(children: [
                                const TextSpan(
                                    text: "API请求地址: ",
                                    style: TextStyle(color: AppColors.mainColor)),
                                TextSpan(
                                    text: WebSQLHttpServer.getInstance()
                                        .getHttpServerPath(),
                                    style: const TextStyle(
                                        color: AppColors.redColor,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline),
                                    recognizer: () {
                                      TapGestureRecognizer tapGestureRecognizer =
                                      TapGestureRecognizer();
                                      tapGestureRecognizer.onTap = () {
                                        String httpServerPath =
                                        WebSQLHttpServer.getInstance()
                                            .getHttpServerPath();
                                        Clipboard.setData(
                                            ClipboardData(text: httpServerPath));
                                        AppToast.show("请求链接已复制!");
                                        launchUrl(Uri.parse(httpServerPath),
                                            mode: LaunchMode.externalApplication)
                                            .onError((error, stackTrace) {
                                          Log.message("launchUrl--error:$error");
                                          return true;
                                        });
                                      };
                                      return tapGestureRecognizer;
                                    }())
                              ])),
                        ),
                      ))
                ],
              );
            }),
      ],
    );
  }

  Widget buildSettingTitleWidget() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Stack(
        children: [
          SpaceWidget.createHeightSpace(1, spaceColor: Colors.grey),
          const Center(
            child: Text(
              "设置",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1E90FF)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SpaceWidget.createHeightSpace(1, spaceColor: Colors.grey),
          )
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  onTabDoubleTap() {}

  @override
  onTabLongTap() {}

  @override
  onTabTap(bool isChangedTab) {}

  @override
  Future<bool> canGoBack() {
    return Future.value(true);
  }
}
