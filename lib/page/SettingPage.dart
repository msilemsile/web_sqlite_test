import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/page/HomePage.dart';
import 'package:web_sqlite_test/service/LanBroadcastService.dart';
import 'package:web_sqlite_test/service/LanConnectService.dart';
import 'package:web_sqlite_test/theme/AppColors.dart';

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
                              onChanged: (newValue) {
                                _lanBroadcastControl.value = newValue;
                                if (newValue) {
                                  LanConnectService.getInstance().bindService();
                                  LanBroadcastService.getInstance()
                                      .startBroadcast();
                                } else {
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
                              onChanged: (newValue) {
                                _httpDBControl.value = newValue;
                                if (newValue) {
                                } else {}
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
            })
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
}
