import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:sqlite3/sqlite3.dart' as sql3;
import 'package:web_sqlite_test/database/DBConstants.dart';
import 'package:web_sqlite_test/database/DBManager.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/model/DBFileInfo.dart';
import 'package:web_sqlite_test/model/EmptyDataList.dart';
import 'package:web_sqlite_test/page/HomePage.dart';
import 'package:web_sqlite_test/theme/AppColors.dart';
import 'package:web_sqlite_test/widget/DBCommandDialog.dart';

import '../database/DBDirConst.dart';

class DatabasePage extends StatefulWidget {
  final OnTabPageCreateListener onTabPageCreateListener;

  const DatabasePage({super.key, required this.onTabPageCreateListener});

  @override
  State<StatefulWidget> createState() {
    return _DatabasePageState();
  }
}

class _DatabasePageState extends State<DatabasePage>
    with AutomaticKeepAliveClientMixin, HomeTabTapController {
  static const int exchangeWorkspaceAction = 0;
  static const int exeSqlAction = 1;
  static const int refreshDatabaseAction = 2;
  static const int newDatabaseAction = 3;

  final PopupWindow _moreActionWindow = PopupWindow();

  final ValueNotifier<DBDirConst> _currentWorkspace =
      ValueNotifier(DBDirConst.local);

  GlobalKey<LiquidPullToRefreshState> pullToRefreshState = GlobalKey();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.onTabPageCreateListener(this);
    });
    _currentWorkspace.value =
        DBWorkspaceManager.getInstance().getCurrentDBDir();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        buildDatabaseTitleWidget(),
        Expanded(
            child: LiquidPullToRefresh(
                key: pullToRefreshState,
                springAnimationDurationInMilliseconds: 400,
                showChildOpacityTransition: false,
                onRefresh: pullToOnRefresh,
                child: FutureBuilder(
                    future: loadCurrentWorkspaceData(),
                    initialData: const [],
                    builder: (buildContext, asyncSnapshot) {
                      List dataList = [];
                      if (asyncSnapshot.connectionState ==
                          ConnectionState.done) {
                        if (asyncSnapshot.data != null &&
                            asyncSnapshot.data!.isNotEmpty) {
                          dataList.addAll(asyncSnapshot.data as Iterable);
                        } else {
                          dataList.add(EmptyDataList());
                        }
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                        itemCount: dataList.length,
                        itemBuilder: (buildContext, index) {
                          dynamic elementAt = dataList[index];
                          if (elementAt is DBFileInfo) {
                            return buildDBFileInfoItemWidget(elementAt);
                          } else if (elementAt is EmptyDataList) {
                            return buildEmptyDBListWidget();
                          }
                          return buildUnknownItemWidget();
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return const Divider(
                            height: 10,
                          );
                        },
                      );
                    })))
      ],
    );
  }

  Widget buildEmptyDBListWidget() {
    return const SizedBox(
      width: double.infinity,
      height: 50,
      child: Center(
        child: Text("暂无数据"),
      ),
    );
  }

  Widget buildUnknownItemWidget() {
    return const SizedBox(
      width: double.infinity,
      height: 50,
      child: Center(
        child: Text("未知类型数据"),
      ),
    );
  }

  Widget buildDBFileInfoItemWidget(DBFileInfo dbFileInfo) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: RectangleShape(
        cornerAll: 3,
        stokeWidth: 1,
        stokeColor: AppColors.mainColor,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                child: Text(
                  "${dbFileInfo.dbFileName}.db",
                  style: const TextStyle(
                      color: AppColors.mainColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          AppAlertDialog.builder()
                              .setTitle("确定删除${dbFileInfo.dbFileName}数据库吗?")
                              .setCancelTxt("取消")
                              .setConfirmCallback((_) async {
                            await DBManager.getInstance()
                                .deleteDatabase(dbFileInfo.dbFileName);
                            setState(() {});
                          }).show(context);
                        },
                        child: const RectangleShape(
                          solidColor: AppColors.redColor,
                          cornerAll: 2,
                          child: SizedBox(
                            width: 80,
                            height: 32,
                            child: Center(
                              child: Text(
                                "删除",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SpaceWidget.createWidthHeightSpace(10, 50),
                      GestureDetector(
                        onTap: () {
                          DBWorkspaceManager.getInstance()
                              .setLastConnectDBFile(dbFileInfo);
                          DBCommandDialog(dbFileInfo: dbFileInfo)
                              .show(context);
                        },
                        child: const RectangleShape(
                          solidColor: AppColors.mainColor,
                          cornerAll: 2,
                          child: SizedBox(
                            width: 80,
                            height: 32,
                            child: Center(
                              child: Text(
                                "连接",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget buildDatabaseTitleWidget() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Stack(
        children: [
          SpaceWidget.createHeightSpace(1, spaceColor: Colors.grey),
          Center(
            child: ValueListenableBuilder(
                valueListenable: _currentWorkspace,
                builder: (buildContext, currentWorkspace, child) {
                  return Text(
                    DBConstants.getDBDirTitle(currentWorkspace),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1E90FF)),
                  );
                }),
          ),
          GestureDetector(
            onTap: () {
              searchAction();
            },
            child: SizedBox(
              width: 50,
              height: 50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Image.asset("images/icon_search.png"),
              ),
            ),
          ),
          Builder(builder: (buildContext) {
            return Positioned(
              right: 0,
              child: GestureDetector(
                onTap: () {
                  moreAction(buildContext);
                },
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Image.asset("images/icon_more.png"),
                  ),
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.bottomCenter,
            child: SpaceWidget.createHeightSpace(1, spaceColor: Colors.grey),
          )
        ],
      ),
    );
  }

  Future<void> pullToOnRefresh() async {
    setState(() {});
  }

  Future<List<DBFileInfo>> loadCurrentWorkspaceData() async {
    return DBWorkspaceManager.getInstance().listWorkspaceDBFile();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  onTabDoubleTap() {
    pullToRefreshState.currentState?.show();
    setState(() {});
  }

  @override
  onTabLongTap() async {
    AppAlertDialog.builder()
        .setTitle("确定删除所有数据库吗?")
        .setCancelTxt("取消")
        .setConfirmCallback((alertDialog) async {
      await DBManager.getInstance().deleteAllDatabase();
      setState(() {});
    }).show(context);
  }

  @override
  onTabTap(bool isChangedTab) {
    if (isChangedTab) {
      return;
    }
  }

  void searchAction() {}

  void moreAction(BuildContext buildContext) {
    _moreActionWindow.show(buildContext, buildMorePopWidget(),
        offsetX: -72, offsetY: 2);
  }

  Widget buildMorePopWidget() {
    return RectangleShape(
        solidColor: Colors.white,
        stokeColor: const Color(0xff1E90FF),
        stokeWidth: 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildPopItemWidget(exchangeWorkspaceAction),
            SpaceWidget.createWidthHeightSpace(120, 1,
                spaceColor: const Color(0xff1E90FF)),
            buildPopItemWidget(exeSqlAction),
            SpaceWidget.createWidthHeightSpace(120, 1,
                spaceColor: const Color(0xff1E90FF)),
            buildPopItemWidget(refreshDatabaseAction),
            SpaceWidget.createWidthHeightSpace(120, 1,
                spaceColor: const Color(0xff1E90FF)),
            buildPopItemWidget(newDatabaseAction)
          ],
        ));
  }

  Widget buildPopItemWidget(int moreAction) {
    return GestureDetector(
      onTap: () {
        invokeMoreAction(moreAction);
      },
      child: SizedBox(
        width: 120,
        height: 45,
        child: Row(
          children: [
            SpaceWidget.createWidthSpace(10),
            Image.asset(
              getMoreActionIcon(moreAction),
              width: 18,
              height: 18,
            ),
            SpaceWidget.createWidthSpace(5),
            Expanded(
                child: Text(
              getMoreActionTitle(moreAction),
              style: const TextStyle(fontSize: 13, color: Color(0xff1E90FF)),
            ))
          ],
        ),
      ),
    );
  }

  String getMoreActionTitle(int moreAction) {
    if (moreAction == exchangeWorkspaceAction) {
      return "切换工作空间";
    } else if (moreAction == exeSqlAction) {
      return "执行SQL语句";
    } else if (moreAction == refreshDatabaseAction) {
      return "刷新工作数据";
    } else if (moreAction == newDatabaseAction) {
      return "新建数据库";
    }
    return "";
  }

  String getMoreActionIcon(int moreAction) {
    if (moreAction == exchangeWorkspaceAction) {
      return "images/icon_exchange.png";
    } else if (moreAction == exeSqlAction) {
      return "images/icon_exec_sql.png";
    } else if (moreAction == refreshDatabaseAction) {
      return "images/icon_refresh_database.png";
    } else if (moreAction == newDatabaseAction) {
      return "images/icon_new_database.png";
    }
    return "";
  }

  void invokeMoreAction(int moreAction) async {
    _moreActionWindow.hide(context);
    if (moreAction == exchangeWorkspaceAction) {
      AppDialog appDialog = AppDialog();
      appDialog.show(context, buildWorkspaceDialog());
    } else if (moreAction == exeSqlAction) {
      DBFileInfo? lastConnectDBFile = DBWorkspaceManager.getInstance().getLastConnectDBFile();
      if (lastConnectDBFile == null) {
        Toast.show(context, "暂无数据");
      } else {
        DBCommandDialog(dbFileInfo: lastConnectDBFile).show(context);
      }
    } else if (moreAction == refreshDatabaseAction) {
      pullToRefreshState.currentState?.show();
      setState(() {});
    } else if (moreAction == newDatabaseAction) {
      TextEditingController editingController = TextEditingController();
      AppAlertDialog.builder()
          .setTitle("新建数据库")
          .setContentWidget(buildCreateDBWidget(editingController))
          .setCancelTxt("取消")
          .setConfirmCallback((_) async {
        String dbName = editingController.text.toString().trim();
        if (dbName.isEmpty) {
          Toast.show(context, "数据库名称不能为空");
        } else {
          sql3.Database? database =
              await DBManager.getInstance().openDatabase(dbName);
          database?.dispose();
          setState(() {});
        }
      }).show(context);
    }
  }

  Widget buildCreateDBWidget(TextEditingController editingController) {
    Widget editDBNameWidget = SizedBox(
      width: double.infinity,
      height: 45,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: Row(
          children: [
            Expanded(
                child: Material(
              color: Colors.transparent,
              child: TextField(
                controller: editingController,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: "输入数据库名称", border: InputBorder.none),
                keyboardType: TextInputType.url,
                cursorColor: const Color(0xff1E90FF),
                style: const TextStyle(color: Color(0xff1E90FF)),
              ),
            )),
            const Text(".db", style: TextStyle(fontSize: 15))
          ],
        ),
      ),
    );
    return editDBNameWidget;
  }

  Widget buildWorkspaceItemWidget(DBDirConst dbDirConst) {
    return GestureDetector(
      onTap: () {
        changeWorkspace(dbDirConst);
      },
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: Stack(
          children: [
            Visibility(
                visible: _currentWorkspace.value == dbDirConst,
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

  Widget buildWorkspaceDialog() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 0, 35, 0),
      child: RectangleShape(
        solidColor: Colors.white,
        stokeColor: const Color(0xff1E90FF),
        cornerAll: 10,
        stokeWidth: 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildWorkspaceItemWidget(DBDirConst.local),
            SpaceWidget.createHeightSpace(1,
                spaceColor: const Color(0xff1E90FF)),
            buildWorkspaceItemWidget(DBDirConst.lan),
            SpaceWidget.createHeightSpace(1,
                spaceColor: const Color(0xff1E90FF)),
            buildWorkspaceItemWidget(DBDirConst.server)
          ],
        ),
      ),
    );
  }

  void changeWorkspace(DBDirConst dbDirConst) {}
}
