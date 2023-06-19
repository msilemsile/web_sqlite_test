import 'package:flutter/material.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/dialog/DBLanConnectDialog.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/service/LanBroadcastService.dart';
import 'package:web_sqlite_test/theme/AppColors.dart';

import '../database/DBConstants.dart';
import '../database/DBDirConst.dart';

typedef OnChangeWorkspaceCallback = Function(DBDirConst dbDirConst,
    [HostInfo? hostInfo]);

class DBWorkspaceDialog extends StatefulWidget {
  final AppDialog appDialog = AppDialog();
  late final BuildContext _buildContext;
  final OnChangeWorkspaceCallback changeWorkspaceCallback;

  DBWorkspaceDialog({super.key, required this.changeWorkspaceCallback});

  @override
  State<StatefulWidget> createState() {
    return _DBWorkspaceDialogState();
  }

  void show(BuildContext context) {
    _buildContext = context;
    appDialog.show(context, this, true, true);
  }

  void hide() {
    appDialog.dismiss(_buildContext);
  }
}

class _DBWorkspaceDialogState extends State<DBWorkspaceDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
                  "选择工作空间",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              buildContentWidget(context),
              SpaceWidget.createHeightSpace(12),
            ],
          ),
        ));
  }

  Widget buildContentWidget(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildWorkspaceItemWidget(DBDirConst.local),
              SpaceWidget.createHeightSpace(1, spaceColor: AppColors.lineColor),
              buildWorkspaceItemWidget(DBDirConst.lan),
              SpaceWidget.createHeightSpace(1, spaceColor: AppColors.lineColor),
              buildWorkspaceItemWidget(DBDirConst.server),
              SpaceWidget.createHeightSpace(1, spaceColor: AppColors.lineColor),
              buildWorkspaceItemWidget(DBDirConst.cacheLan),
              SpaceWidget.createHeightSpace(1, spaceColor: AppColors.lineColor),
              buildWorkspaceItemWidget(DBDirConst.cacheServer),
              SpaceWidget.createHeightSpace(1, spaceColor: AppColors.lineColor),
              buildWorkspaceItemWidget(DBDirConst.temp)
            ],
          ),
        ),
      ),
    );
  }

  Widget buildWorkspaceItemWidget(DBDirConst dbDirConst) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        var currentDBDir = DBWorkspaceManager.getInstance().getCurrentDBDir();
        if (dbDirConst != DBDirConst.lan && dbDirConst != DBDirConst.server) {
          if (currentDBDir == dbDirConst) {
            return;
          }
        }
        if (dbDirConst == DBDirConst.local ||
            dbDirConst == DBDirConst.cacheLan ||
            dbDirConst == DBDirConst.cacheServer ||
            dbDirConst == DBDirConst.temp) {
          widget.changeWorkspaceCallback(dbDirConst);
          widget.hide();
        } else if (dbDirConst == DBDirConst.lan) {
          bool listeningBroadcast =
              LanBroadcastService.getInstance().isListeningBroadcast();
          if (!listeningBroadcast) {
            AppToast.show("请在设置页打开局域网数据互操作");
            return;
          }
          DBLanConnectDialog(
            onSelectHostCallback: (selectHostInfo) {
              widget.changeWorkspaceCallback(dbDirConst, selectHostInfo);
              widget.hide();
            },
          ).show(context);
        } else if (dbDirConst == DBDirConst.server) {
          AppToast.show("该功能开发中");
        }
      },
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: Stack(
          children: [
            Visibility(
                visible: DBWorkspaceManager.getInstance().getCurrentDBDir() ==
                    dbDirConst,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Image.asset(
                      "images/icon_focus.png",
                      colorBlendMode: BlendMode.srcATop,
                      color: Colors.red,
                      width: 20,
                      height: 20,
                    ),
                  ),
                )),
            Center(
              child: Text(
                DBConstants.getDBDirTitle(dbDirConst),
                style: const TextStyle(color: Color(0xff1E90FF)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
