import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/model/WebSQLRouter.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';
import 'package:web_sqlite_test/router/RouterManager.dart';
import 'package:web_sqlite_test/service/LanBroadcastService.dart';
import 'package:web_sqlite_test/service/LanConnectService.dart';
import 'package:web_sqlite_test/theme/AppColors.dart';
import 'package:web_sqlite_test/utils/HostHelper.dart';

import '../model/HostInfo.dart';

typedef OnSelectHostCallback = Function(HostInfo hostInfo);

class DBLanConnectDialog extends StatefulWidget {
  final AppDialog appDialog = AppDialog();
  late final BuildContext _buildContext;
  final OnSelectHostCallback onSelectHostCallback;

  DBLanConnectDialog({super.key, required this.onSelectHostCallback});

  @override
  State<StatefulWidget> createState() {
    return _DBLanConnectDialogState();
  }

  void show(BuildContext context) {
    _buildContext = context;
    appDialog.show(context, this, false, false);
  }

  void hide() {
    appDialog.dismiss(_buildContext);
  }
}

class _DBLanConnectDialogState extends State<DBLanConnectDialog> {
  final ValueNotifier<int> _currentSelectHost = ValueNotifier(0);
  final List<HostInfo> _hostInfoList = [];
  OnLanBroadcastCallback? _broadcastCallback;

  @override
  void initState() {
    super.initState();
    _broadcastCallback = (result) {
      WebSQLRouter? webSQLRouter = RouterManager.parseToWebSQLRouter(result);
      if (webSQLRouter != null &&
          webSQLRouter.action != null &&
          RouterConstants.actionBroadcast.compareTo(webSQLRouter.action!) ==
              0) {
        Map<String, dynamic>? jsonData = webSQLRouter.jsonData;
        if (jsonData != null) {
          String host = jsonData[RouterConstants.dataHost];
          if (host.isNotEmpty) {
            for (HostInfo hostInfo in _hostInfoList) {
              if (hostInfo.host.compareTo(host) == 0) {
                return;
              }
            }
            String platform = jsonData[RouterConstants.dataPlatform];
            _hostInfoList.add(HostInfo(host, platform));
            setState(() {});
          }
        }
      }
    };
    () async {
      var currentHostInfo = await HostHelper.getInstance().getLocalHostInfo();
      if (currentHostInfo != null) {
        _hostInfoList.add(currentHostInfo);
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          LanBroadcastService.getInstance().listenBroadcast(_broadcastCallback);
          setState(() {});
        });
      } else {
        AppToast.show("获取局域网ip失败,请检查网络连接");
      }
    }();
  }

  @override
  void dispose() {
    LanBroadcastService.getInstance()
        .removeBroadcastCallback(_broadcastCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(35, 0, 35, 0),
        child: RectangleShape(
          solidColor: AppColors.whiteColor,
          stokeColor: AppColors.lineColor,
          cornerAll: 10,
          stokeWidth: 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpaceWidget.createHeightSpace(12),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  "局域网数据库主机",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              buildContentWidget(context),
              SpaceWidget.createHeightSpace(0.5,
                  spaceColor: AppColors.lineColor),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: buildBottomWidget(context),
              )
            ],
          ),
        ));
  }

  Widget buildContentWidget(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: ListView.separated(
          itemCount: _hostInfoList.length + 1,
          separatorBuilder: (buildContext, index) {
            return const Divider(
              color: AppColors.lineColor,
              height: 1,
            );
          },
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          itemBuilder: (buildContext, index) {
            if (index == _hostInfoList.length) {
              return const SizedBox(
                width: double.infinity,
                height: 45,
                child: Center(
                  child: Text("扫描中..."),
                ),
              );
            }
            HostInfo hostInfo = _hostInfoList[index];
            return buildHostItemWidget(hostInfo, index);
          }),
    );
  }

  Widget buildHostItemWidget(HostInfo hostInfo, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_currentSelectHost.value == index) {
          return;
        }
        _currentSelectHost.value = index;
        setState(() {});
      },
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: Row(
          children: [
            Image.asset(
              hostInfo.getPlatformIcon(),
              width: 25,
              height: 25,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              child: Text(
                "${hostInfo.host}",
                style: const TextStyle(color: AppColors.mainColor),
              ),
            ),
            Visibility(
                visible: hostInfo.isLocalHost(),
                child: const Text(
                  "(本机)",
                  style: TextStyle(color: AppColors.redColor),
                )),
            Expanded(
                child: Visibility(
              visible: _currentSelectHost.value == index,
              child: Align(
                alignment: Alignment.centerRight,
                child: Image.asset(
                  "images/icon_focus.png",
                  colorBlendMode: BlendMode.srcATop,
                  color: Colors.red,
                  width: 20,
                  height: 20,
                ),
              ),
            ))
          ],
        ),
      ),
    );
  }

  Widget buildBottomWidget(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: Text("取消"),
          ),
          onTap: () {
            widget.hide();
          },
        )),
        SpaceWidget.createWidthSpace(0.5, spaceColor: AppColors.lineColor),
        Expanded(
            child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: Text(
              "连接",
              style: TextStyle(color: AppColors.mainColor),
            ),
          ),
          onTap: () async {
            if (_hostInfoList.isEmpty) {
              return;
            }
            int index = _currentSelectHost.value;
            HostInfo hostInfo = _hostInfoList[index];
            if (hostInfo.isLocalHost()) {
              AppToast.show("已切换到本地LAN缓存空间");
              LanConnectService.getInstance().unConnectService();
              widget.onSelectHostCallback(hostInfo);
              widget.hide();
              return;
            }
            String? wifiIP = await HostHelper.getInstance().getWifiIP();
            if (wifiIP == null) {
              AppToast.show("获取ip失败,请检查网络连接");
              return;
            }
            LanConnectService.getInstance().connectService(hostInfo,
                (connectState) {
              if (connectState
                      .compareTo(LanConnectService.connectStateSuccess) ==
                  0) {
                widget.onSelectHostCallback(hostInfo);
                widget.hide();
              } else {
                AppToast.show(connectState);
              }
            });
          },
        ))
      ],
    );
  }
}
