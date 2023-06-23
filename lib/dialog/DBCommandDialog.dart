import 'package:flutter/material.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/database/DBCommandHelper.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/theme/AppColors.dart';

class DBCommandDialog extends StatefulWidget {
  final String databaseName;
  final AppDialog appDialog = AppDialog();
  late final BuildContext _buildContext;

  DBCommandDialog({super.key, required this.databaseName});

  @override
  State<StatefulWidget> createState() {
    return _DBCommandDialogState();
  }

  void show(BuildContext context) {
    _buildContext = context;
    appDialog.show(context, this, false, false);
  }

  void hide() {
    appDialog.dismiss(_buildContext);
  }
}

class _DBCommandDialogState extends State<DBCommandDialog> {
  TextEditingController editingController = TextEditingController();

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
                  "SQL命令控制台",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              buildContentWidget(context),
              SpaceWidget.createHeightSpace(16),
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: Column(
          children: [
            Text("当前连接的数据库: ${widget.databaseName}"),
            SpaceWidget.createHeightSpace(10),
            Expanded(
                child: RectangleShape(
              solidColor: Colors.black,
              cornerAll: 5,
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  scrollPadding: EdgeInsets.zero,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  controller: editingController,
                  autofocus: true,
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                      hintText: "输入SQL命令",
                      border: InputBorder.none),
                  keyboardType: TextInputType.url,
                  cursorColor: Colors.yellow,
                  style: const TextStyle(color: Colors.yellow),
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
            child: Text("断开"),
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
            child: Text("清空"),
          ),
          onTap: () {
            editingController.text = "";
          },
        )),
        SpaceWidget.createWidthSpace(0.5, spaceColor: AppColors.lineColor),
        Expanded(
            child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: Text(
              "执行",
              style: TextStyle(color: AppColors.mainColor),
            ),
          ),
          onTap: () {
            String sqlExec = editingController.text.toString().trim();
            if (sqlExec.isEmpty) {
              AppToast.show("sql命令不能为空");
              return;
            } else {
              DBWorkspaceManager.getInstance()
                  .execSql(widget.databaseName, false, sqlExec, const [],
                      (execSqlResult) {
                DBCommandHelper.showExecSqlResult(context, execSqlResult);
              });
            }
          },
        ))
      ],
    );
  }
}
