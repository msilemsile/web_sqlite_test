import 'dart:io';

import 'package:flutter_app/flutter_app.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:web_sqlite_test/utils/StorageHelper.dart';

import '../model/DBFileInfo.dart';
import 'DBDirConst.dart';

class DBWorkspaceManager {
  DBWorkspaceManager._();

  static DBWorkspaceManager? _dbWorkspaceManager;

  static DBWorkspaceManager getInstance() {
    _dbWorkspaceManager ??= DBWorkspaceManager._();
    return _dbWorkspaceManager!;
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

  Future<String?> getWifiIP() async {
    NetworkInfo networkInfo = NetworkInfo();
    return networkInfo.getWifiIP();
  }

  Future<List<DBFileInfo>> listWorkspaceDBFile([DBDirConst? dirConst]) async {
    String dbDirPath = await StorageHelper.getDatabaseDirPath(dirConst);
    Directory dbDir = Directory(dbDirPath);
    List<FileSystemEntity> listFileSync = dbDir.listSync();
    List<DBFileInfo> dbFileInfoList = [];
    for (FileSystemEntity fileEntity in listFileSync) {
      String filePath = fileEntity.path;
      Log.message("application listWorkspaceDBFile : $filePath");
      String fileExtension = path.extension(filePath);
      String fileName = path.basenameWithoutExtension(filePath);
      if (fileExtension.contains(".db")) {
        dbFileInfoList.add(DBFileInfo(fileName, filePath));
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
}
