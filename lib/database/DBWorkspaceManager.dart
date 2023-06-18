import 'dart:io';

import 'package:flutter_app/flutter_app.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/src/ffi/api.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/model/WebSQLRouter.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';
import 'package:web_sqlite_test/service/LanConnectService.dart';
import 'package:web_sqlite_test/utils/StorageHelper.dart';

import '../model/DBFileInfo.dart';
import 'DBCommandHelper.dart';
import 'DBDirConst.dart';
import 'DBFileHelper.dart';

class DBWorkspaceManager with OnSendWebRouterMessageCallback{
  DBWorkspaceManager._();

  static DBWorkspaceManager? _dbWorkspaceManager;

  static DBWorkspaceManager getInstance() {
    _dbWorkspaceManager ??= DBWorkspaceManager._();
    return _dbWorkspaceManager!;
  }

  final Map<String, DBCommandHelper> _dbCommandHelperMap = {};

  DBCommandHelper getDBCommandHelper(String databaseName) {
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
  final List<DBFileInfo> _currentDBFileList = [];

  void setCurrentDBDir(DBDirConst dbDirConst) {
    _currentDBDir = dbDirConst;
  }

  DBDirConst getCurrentDBDir() {
    return _currentDBDir;
  }

  List<DBFileInfo> getCurrentDBFileList() {
    return _currentDBFileList;
  }

  void setLastConnectDBFile(DBFileInfo dbFileInfo) {
    _lastConnectDBFile = dbFileInfo;
  }

  DBFileInfo? getLastConnectDBFile() {
    return _lastConnectDBFile;
  }

  Future<Database?>? openOrCreateWorkspaceDB(String databaseName) {
    return DBFileHelper.openDatabase(databaseName);
  }

  Future<void> deleteWorkspaceDB(String databaseName) {
    DBCommandHelper? commandHelper = _dbCommandHelperMap[databaseName];
    if (commandHelper != null) {
      commandHelper.disposeDatabase();
    }
    return DBFileHelper.deleteDatabase(databaseName);
  }

  Future<List<DBFileInfo>> listWorkspaceDBFile([DBDirConst? dbDirConst]) async {
    dbDirConst ??= _currentDBDir;
    List<DBFileInfo> dbFileInfoList = [];
    if (_currentDBDir == DBDirConst.lan) {
      HostInfo? connectHostInfo = LanConnectService.getInstance()
          .getCurrentConnectHostInfo();
      if (connectHostInfo != null) {
        LanConnectService.getInstance()
            .sendMessage(RouterConstants.buildListDBRoute());
      }
    } else {
      String dbDirPath = await StorageHelper.getDatabaseDirPath(dirConst);
      Directory dbDir = Directory(dbDirPath);
      List<FileSystemEntity> listFileSync = dbDir.listSync();
      for (FileSystemEntity fileEntity in listFileSync) {
        String filePath = fileEntity.path;
        Log.message("application listWorkspaceDBFile : $filePath");
        String fileExtension = path.extension(filePath);
        String fileName = path.basenameWithoutExtension(filePath);
        if (fileExtension.contains(".db")) {
          dbFileInfoList.add(DBFileInfo(fileName, filePath));
        }
      }
    }
    _currentDBFileList.clear();
    _lastConnectDBFile = null;
    _currentDBFileList.addAll(dbFileInfoList);
    if (_currentDBFileList.isNotEmpty) {
      _lastConnectDBFile = _currentDBFileList[0];
    }
    return _currentDBFileList;
  }

  @override
  onMessageCallback(WebSQLRouter webSQLRouter) {

  }
}
