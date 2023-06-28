import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:web_sqlite_test/database/DBConstants.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/dialog/DBCommandDialog.dart';
import 'package:web_sqlite_test/dialog/DBWorkspaceDialog.dart';
import 'package:web_sqlite_test/model/DBFileInfo.dart';
import 'package:web_sqlite_test/model/EmptyDataList.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/page/HomePage.dart';
import 'package:web_sqlite_test/service/LanConnectService.dart';
import 'package:web_sqlite_test/service/OnLanConnectCallback.dart';
import 'package:web_sqlite_test/theme/AppColors.dart';

import '../database/DBDirConst.dart';
import '../widget/TriangleShapeWidget.dart';

class DatabasePage extends StatefulWidget {
  final OnTabPageCreateListener onTabPageCreateListener;

  const DatabasePage({super.key, required this.onTabPageCreateListener});

  @override
  State<StatefulWidget> createState() {
    return _DatabasePageState();
  }
}

class _DatabasePageState extends State<DatabasePage>
    with
        AutomaticKeepAliveClientMixin,
        HomeTabTapController,
        OnLanConnectCallback {
  static const int exchangeWorkspaceAction = 0;
  static const int exeSqlAction = 1;
  static const int refreshDatabaseAction = 2;
  static const int newDatabaseAction = 3;

  final PopupWindow _moreActionWindow = PopupWindow();

  final ValueNotifier<DBDirConst> _currentWorkspace =
      ValueNotifier(DBDirConst.local);
  final ValueNotifier<HostInfo?> _currentHostInfo = ValueNotifier(null);
  final ValueNotifier<List> _currentDBFileList =
      ValueNotifier([EmptyDataList()]);

  GlobalKey<LiquidPullToRefreshState> pullToRefreshState = GlobalKey();

  @override
  void initState() {
    super.initState();
    LanConnectService.getInstance().addLanConnectCallback(this);
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.onTabPageCreateListener(this);
      refreshListData();
    });
    _currentWorkspace.value =
        DBWorkspaceManager.getInstance().getCurrentDBDir();
  }

  @override
  void dispose() {
    LanConnectService.getInstance().removeLanConnectCallback(this);
    super.dispose();
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
                onRefresh: () async {
                  loadWorkspaceDBFile();
                },
                child: ValueListenableBuilder(
                    valueListenable: _currentDBFileList,
                    builder: (buildContext, dataList, child) {
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
            Visibility(
                visible: DBWorkspaceManager.getInstance().isRemoteDBDir(),
                child: Transform.rotate(
                    angle: -pi / 4,
                    child: TriangleShapeWidget(
                      AppColors.redColor,
                      15,
                      15,
                      child: Image.asset(
                        "images/icon_remote_control.png",
                        width: 15,
                        height: 15,
                        color: AppColors.whiteColor,
                      ),
                    ))),
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
                              .setConfirmCallback((_) {
                            DBWorkspaceManager.getInstance().deleteWorkspaceDB(
                                dbFileInfo.dbFileName, (result) {
                              if (result.compareTo("1") == 0) {
                                AppToast.show(
                                    "删除${dbFileInfo.dbFileName}数据库成功");
                                refreshListData();
                              } else {
                                AppToast.show(
                                    "删除${dbFileInfo.dbFileName}数据库失败!");
                              }
                            });
                          }).show(context);
                        },
                        child: const RectangleShape(
                          solidColor: AppColors.redColor,
                          cornerAll: 2,
                          child: SizedBox(
                            width: 60,
                            height: 30,
                            child: Center(
                              child: Text(
                                "删除",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SpaceWidget.createWidthHeightSpace(5, 50),
                      GestureDetector(
                        onTap: () {
                          DBWorkspaceManager.getInstance()
                              .setLastConnectDBFile(dbFileInfo);
                          DBCommandDialog(databaseName: dbFileInfo.dbFileName)
                              .show(context);
                        },
                        child: const RectangleShape(
                          solidColor: AppColors.mainColor,
                          cornerAll: 2,
                          child: SizedBox(
                            width: 60,
                            height: 30,
                            child: Center(
                              child: Text(
                                "命令",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                          visible:
                              DBWorkspaceManager.getInstance().isRemoteDBDir(),
                          child: Row(
                            children: [
                              SpaceWidget.createWidthHeightSpace(5, 50),
                              GestureDetector(
                                onTap: () {
                                  DBWorkspaceManager.getInstance()
                                      .downloadWorkspaceDB(
                                          dbFileInfo.dbFileName,
                                          (dbName, result) {
                                    if (result.compareTo("1") == 0) {
                                      AppToast.show(
                                          "下载${dbFileInfo.dbFileName}数据库成功");
                                      DBDirConst currentDBDir =
                                          DBWorkspaceManager.getInstance()
                                              .getCurrentDBDir();
                                      if (currentDBDir == DBDirConst.lan) {
                                        currentDBDir = DBDirConst.cacheLan;
                                      } else if (currentDBDir ==
                                          DBDirConst.server) {
                                        currentDBDir = DBDirConst.cacheServer;
                                      }
                                      AppAlertDialog.builder()
                                          .setTitle("提示")
                                          .setContent(
                                              "下载成功,数据库保存在\"工作空间->${DBConstants.getDBDirTitle(currentDBDir)}\",请手动切换至该工作空间")
                                          .show(context);
                                    } else {
                                      AppToast.show(
                                          "下载${dbFileInfo.dbFileName}数据库失败!");
                                    }
                                  });
                                },
                                child: const RectangleShape(
                                  solidColor: AppColors.mainColor,
                                  cornerAll: 2,
                                  child: SizedBox(
                                    width: 60,
                                    height: 30,
                                    child: Center(
                                      child: Text(
                                        "下载",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )),
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
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DBConstants.getDBDirTitle(currentWorkspace),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainColor),
                      ),
                      Visibility(
                          visible: _currentHostInfo.value != null,
                          child: Text(
                            "主机:${_currentHostInfo.value?.host}",
                            style: const TextStyle(
                                color: AppColors.redColor, fontSize: 13),
                          ))
                    ],
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

  void refreshListData() {
    pullToRefreshState.currentState?.show();
    setState(() {});
  }

  void loadWorkspaceDBFile() async {
    Log.message("DatabasePage--pullToOnRefresh");
    DBWorkspaceManager.getInstance().listWorkspaceDBFile((dbFileList) {
      if (dbFileList.isEmpty) {
        _currentDBFileList.value = [EmptyDataList()];
      } else {
        _currentDBFileList.value = dbFileList;
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  onTabDoubleTap() {
    refreshListData();
  }

  @override
  onTabLongTap() async {}

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
      behavior: HitTestBehavior.opaque,
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
      DBWorkspaceDialog(
        changeWorkspaceCallback: (DBDirConst dbDirConst, [HostInfo? hostInfo]) {
          if (hostInfo != null && hostInfo.isLocalHost()) {
            changDBLocalSpace();
          } else {
            _currentWorkspace.value = dbDirConst;
            _currentHostInfo.value = hostInfo;
            DBWorkspaceManager.getInstance().setCurrentDBDir(dbDirConst);
            refreshListData();
          }
        },
      ).show(context);
    } else if (moreAction == exeSqlAction) {
      List dbFileList = _currentDBFileList.value;
      if (dbFileList.isEmpty) {
        AppToast.show("暂无数据");
      } else {
        dynamic firstDBFile = dbFileList[0];
        if (firstDBFile is EmptyDataList) {
          AppToast.show("暂无数据");
        } else {
          DBFileInfo? lastConnectDBFile =
              DBWorkspaceManager.getInstance().getLastConnectDBFile();
          if (lastConnectDBFile == null) {
            lastConnectDBFile = firstDBFile;
            DBWorkspaceManager.getInstance().setLastConnectDBFile(firstDBFile);
          }
          DBCommandDialog(databaseName: lastConnectDBFile!.dbFileName)
              .show(context);
        }
      }
    } else if (moreAction == refreshDatabaseAction) {
      refreshListData();
    } else if (moreAction == newDatabaseAction) {
      TextEditingController editingController = TextEditingController();
      AppAlertDialog.builder()
          .setTitle("新建数据库")
          .setNeedHandleKeyboard(true)
          .setContentWidget(buildCreateDBWidget(editingController))
          .setCancelTxt("取消")
          .setConfirmCallback((_) async {
        String dbName = editingController.text.toString().trim();
        if (dbName.isEmpty) {
          AppToast.show("数据库名称不能为空");
        } else {
          DBWorkspaceManager.getInstance().openOrCreateWorkspaceDB(dbName,
              (result) {
            if (result.compareTo("1") == 0) {
              AppToast.show("创建数据库$dbName成功");
              refreshListData();
            } else {
              AppToast.show("创建数据库$dbName失败!");
            }
          });
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

  @override
  Future<bool> canGoBack() {
    return Future.value(true);
  }

  void changDBLocalSpace() {
    AppToast.show("已切换到本地空间");
    _currentWorkspace.value = DBDirConst.local;
    _currentHostInfo.value = null;
    DBWorkspaceManager.getInstance().setCurrentDBDir(DBDirConst.local);
    refreshListData();
  }

  @override
  onConnectState(String connectState) {
    if (connectState == LanConnectService.connectStateDisconnect) {
      if (_currentWorkspace.value == DBDirConst.lan) {
        changDBLocalSpace();
      }
    }
  }
}
