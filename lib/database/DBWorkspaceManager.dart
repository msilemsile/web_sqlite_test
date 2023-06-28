import 'dart:io';

import 'package:flutter_app/flutter_app.dart';
import 'package:path/path.dart' as path;
import 'package:web_sqlite_test/router/RouterConstants.dart';
import 'package:web_sqlite_test/router/RouterManager.dart';
import 'package:web_sqlite_test/router/WebSQLRouterCallback.dart';
import 'package:web_sqlite_test/service/LanConnectService.dart';
import 'package:web_sqlite_test/service/WebSQLHttpClient.dart';
import 'package:web_sqlite_test/utils/StorageHelper.dart';

import '../model/DBFileInfo.dart';
import 'DBCommandHelper.dart';
import 'DBDirConst.dart';
import 'DBFileHelper.dart';

typedef OnOpenOrCreateDBCallback = Function(String result);
typedef OnDeleteDBCallback = Function(String result);
typedef OnWebSQLExecResultCallback = Function(String result);
typedef OnWebSQLListDBCallback = Function(List<DBFileInfo> dbFileList);

class DBWorkspaceManager with WebSQLRouterCallback {
  DBWorkspaceManager._();

  final Map<String, OnWebSQLExecResultCallback> _execSQLCallbackMap = {};
  final Map<String, OnWebSQLListDBCallback> _listDBCallbackMap = {};
  final Map<String, OnOpenOrCreateDBCallback> _openOrCreateDBCallbackMap = {};
  final Map<String, OnDeleteDBCallback> _deleteDBCallbackMap = {};

  static DBWorkspaceManager? _dbWorkspaceManager;

  static DBWorkspaceManager getInstance() {
    _dbWorkspaceManager ??= DBWorkspaceManager._();
    LanConnectService.getInstance().addWebRouterCallback(_dbWorkspaceManager!);
    WebSQLHttpClient.getInstance().addWebRouterCallback(_dbWorkspaceManager!);
    return _dbWorkspaceManager!;
  }

  void release() {
    _lastConnectDBFile = null;
    _execSQLCallbackMap.clear();
    _listDBCallbackMap.clear();
    disposeAllDatabase();
    LanConnectService.getInstance().removeWebRouterCallback(this);
    WebSQLHttpClient.getInstance().removeWebRouterCallback(this);
  }

  final Map<String, DBCommandHelper> _dbCommandHelperMap = {};

  DBCommandHelper _getDBCommandHelper(String databaseName) {
    DBCommandHelper? commandHelper = _dbCommandHelperMap[databaseName];
    if (commandHelper == null) {
      commandHelper = DBCommandHelper.builder(databaseName);
      _dbCommandHelperMap[databaseName] = DBCommandHelper.builder(databaseName);
    }
    return commandHelper;
  }

  void disposeAllDatabase() {
    for (DBCommandHelper commandHelper in _dbCommandHelperMap.values) {
      commandHelper.disposeDatabase();
    }
    _dbCommandHelperMap.clear();
  }

  DBFileInfo? _lastConnectDBFile;
  DBDirConst _currentDBDir = DBDirConst.local;

  void setCurrentDBDir(DBDirConst dbDirConst) {
    if (_currentDBDir != dbDirConst) {
      release();
      LanConnectService.getInstance().addWebRouterCallback(this);
      WebSQLHttpClient.getInstance().addWebRouterCallback(this);
    }
    _currentDBDir = dbDirConst;
  }

  DBDirConst getCurrentDBDir() {
    return _currentDBDir;
  }

  void setLastConnectDBFile(DBFileInfo dbFileInfo) {
    _lastConnectDBFile = dbFileInfo;
  }

  DBFileInfo? getLastConnectDBFile() {
    return _lastConnectDBFile;
  }

  void openOrCreateWorkspaceDB(
      String databaseName, OnOpenOrCreateDBCallback createDBCallback,
      [DBDirConst? dbDirConst]) {
    dbDirConst ??= _currentDBDir;
    if (dbDirConst == DBDirConst.lan) {
      String routerId =
          RouterManager.buildTempRouterId(RouterConstants.actionCreateDB);
      _openOrCreateDBCallbackMap[routerId] = createDBCallback;
      LanConnectService.getInstance().sendMessage(
          RouterConstants.buildCreateDBRoute(databaseName, routerId));
    } else if (dbDirConst == DBDirConst.server) {
      String routerId =
          RouterManager.buildTempRouterId(RouterConstants.actionCreateDB);
      _openOrCreateDBCallbackMap[routerId] = createDBCallback;
      WebSQLHttpClient.getInstance().openOrCreateDB(databaseName, routerId);
    } else {
      DBFileHelper.openDatabase(databaseName, dbDirConst)?.then((value) {
        if (value != null) {
          createDBCallback("1");
        } else {
          createDBCallback("0");
        }
      }).onError((error, stackTrace) {
        createDBCallback("0");
      });
    }
  }

  void deleteWorkspaceDB(
      String databaseName, OnDeleteDBCallback deleteDBCallback,
      [DBDirConst? dbDirConst]) {
    dbDirConst ??= _currentDBDir;
    if (dbDirConst == DBDirConst.lan) {
      String routerId =
          RouterManager.buildTempRouterId(RouterConstants.actionDeleteDB);
      _deleteDBCallbackMap[routerId] = deleteDBCallback;
      LanConnectService.getInstance().sendMessage(
          RouterConstants.buildDeleteDBRoute(databaseName, routerId));
    } else if (dbDirConst == DBDirConst.server) {
      String routerId =
          RouterManager.buildTempRouterId(RouterConstants.actionDeleteDB);
      _deleteDBCallbackMap[routerId] = deleteDBCallback;
      WebSQLHttpClient.getInstance().deleteDB(databaseName, routerId);
    } else {
      DBCommandHelper? commandHelper = _dbCommandHelperMap[databaseName];
      if (commandHelper != null) {
        commandHelper.disposeDatabase();
      }
      DBFileHelper.deleteDatabase(databaseName, dbDirConst).then((value) {
        deleteDBCallback("1");
      }).onError((error, stackTrace) {
        deleteDBCallback("0");
      });
    }
  }

  void execSql(String databaseName, String sqlExec, List<dynamic>? parameters,
      OnWebSQLExecResultCallback resultCallback,
      [DBDirConst? dbDirConst]) {
    dbDirConst ??= _currentDBDir;
    if (dbDirConst == DBDirConst.lan) {
      String routerId = RouterManager.buildTempRouterId();
      _execSQLCallbackMap[routerId] = resultCallback;
      LanConnectService.getInstance().sendMessage(
          RouterConstants.buildExecSQLRoute(databaseName, sqlExec, routerId));
    } else if (dbDirConst == DBDirConst.server) {
      String routerId = RouterManager.buildTempRouterId();
      _execSQLCallbackMap[routerId] = resultCallback;
      WebSQLHttpClient.getInstance().execSQL(databaseName, sqlExec, routerId);
    } else {
      DBCommandHelper dbCommandHelper = _getDBCommandHelper(databaseName);
      dbCommandHelper.execSql(dbDirConst, sqlExec, parameters, (result) {
        resultCallback(result);
      });
    }
  }

  void listWorkspaceDBFile(OnWebSQLListDBCallback onListDBCallback,
      [DBDirConst? dbDirConst]) {
    dbDirConst ??= _currentDBDir;
    _lastConnectDBFile = null;
    List<DBFileInfo> dbFileInfoList = [];
    if (dbDirConst == DBDirConst.lan) {
      String routerId =
          RouterManager.buildTempRouterId(RouterConstants.actionListDB);
      _listDBCallbackMap[routerId] = onListDBCallback;
      LanConnectService.getInstance()
          .sendMessage(RouterConstants.buildListDBRoute(routerId));
    } else if (dbDirConst == DBDirConst.server) {
      String routerId =
          RouterManager.buildTempRouterId(RouterConstants.actionListDB);
      _listDBCallbackMap[routerId] = onListDBCallback;
      WebSQLHttpClient.getInstance().listDB(routerId);
    } else {
      StorageHelper.getDatabaseDirPath().then((dbDirPath) {
        Directory dbDir = Directory(dbDirPath);
        dbDir.list().listen((fileEntity) {
          String filePath = fileEntity.path;
          Log.message("application listWorkspaceDBFile : $filePath");
          String fileExtension = path.extension(filePath);
          String fileName = path.basenameWithoutExtension(filePath);
          if (fileExtension.contains(".db")) {
            dbFileInfoList.add(DBFileInfo(fileName, filePath));
          }
        }, onDone: () {
          onListDBCallback(dbFileInfoList);
        }, onError: (error) {
          onListDBCallback(dbFileInfoList);
        });
      });
    }
  }

  @override
  onExecSQLResult(String result, [String? routerId]) {
    Log.message("onExecSQLResult--routerId: $routerId || result: $result");
    if (routerId != null) {
      OnWebSQLExecResultCallback? execSQLCallback =
          _execSQLCallbackMap[routerId];
      if (execSQLCallback != null) {
        execSQLCallback(result);
        _execSQLCallbackMap.remove(routerId);
      }
    }
  }

  @override
  onListDBFile(List<DBFileInfo> dbFileList, [String? routerId]) {
    Log.message("onListDBFile--routerId: $routerId || dbFileList: $dbFileList");
    if (routerId != null) {
      OnWebSQLListDBCallback? listDBCallback = _listDBCallbackMap[routerId];
      if (listDBCallback != null) {
        listDBCallback(dbFileList);
        _listDBCallbackMap.remove(routerId);
      }
    }
  }

  @override
  onDeleteDB(String result, [String? routerId]) {
    Log.message("onDeleteDB--routerId: $routerId || result: $result");
    if (routerId != null) {
      OnOpenOrCreateDBCallback? callback = _deleteDBCallbackMap[routerId];
      if (callback != null) {
        callback(result);
        _deleteDBCallbackMap.remove(routerId);
      }
    }
  }

  @override
  onOpenOrCreateDB(String result, [String? routerId]) {
    Log.message("onOpenOrCreateDB--routerId: $routerId || result: $result");
    if (routerId != null) {
      OnDeleteDBCallback? callback = _openOrCreateDBCallbackMap[routerId];
      if (callback != null) {
        callback(result);
        _openOrCreateDBCallbackMap.remove(routerId);
      }
    }
  }
}
