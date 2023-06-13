import 'package:flutter/material.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/dialog/DBLanConnectDialog.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/theme/AppColors.dart';

import '../database/DBConstants.dart';
import '../database/DBDirConst.dart';

class DBWorkspaceDialog extends StatefulWidget {
  final AppDialog appDialog = AppDialog();
  late final BuildContext _buildContext;

  DBWorkspaceDialog({super.key});

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
            ],
          ),
        ));
  }

  Widget buildContentWidget(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildWorkspaceItemWidget(DBDirConst.local),
            SpaceWidget.createHeightSpace(1, spaceColor: AppColors.lineColor),
            buildWorkspaceItemWidget(DBDirConst.lan),
            SpaceWidget.createHeightSpace(1, spaceColor: AppColors.lineColor),
            buildWorkspaceItemWidget(DBDirConst.server)
          ],
        ),
      ),
    );
  }

  Widget buildWorkspaceItemWidget(DBDirConst dbDirConst) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        var currentDBDir = DBWorkspaceManager.getInstance().getCurrentDBDir();
        if (currentDBDir == dbDirConst) {
          return;
        }
        if (dbDirConst == DBDirConst.local) {
          AppAlertDialog.builder()
              .setTitle("切换到本地数据会断开所有连接，确定切换吗？")
              .setCancelTxt("取消")
              .setConfirmTxt("确定")
              .setConfirmCallback((alertDialog) {
            DBWorkspaceManager.getInstance().setCurrentDBDir(dbDirConst);
            setState(() {});
          }).show(context);
        } else if (dbDirConst == DBDirConst.lan) {
          DBLanConnectDialog(onSelectHostCallback: (selectHostInfo){
            AppToast.show()
          },).show(context);
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
