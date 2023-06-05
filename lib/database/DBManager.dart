import 'dart:io';

import 'package:flutter_app/flutter_app.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:web_sqlite_test/utils/StorageHelper.dart';

import 'DBCommandHelper.dart';
import 'DBDirConst.dart';

class DBManager {
  DBManager._();

  static DBManager? _dbManager;

  static DBManager getInstance() {
    _dbManager ??= DBManager._();
    return _dbManager!;
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

  Future<Database?>? openDatabase(String? databaseName,
      [DBDirConst? dirConst]) async {
    try {
      if (databaseName == null || databaseName.isEmpty) {
        return null;
      }
      if (!databaseName.endsWith(".db")) {
        databaseName = "$databaseName.db";
      }
      String dbFilePath =
          await StorageHelper.getDatabaseFilePath(databaseName, dirConst);
      Log.message("application create db file : $dbFilePath");
      Database database = sqlite3.open(dbFilePath);
      return database;
    } catch (exception) {
      Log.message("application create db error: $exception");
    }
    return null;
  }

  Future<void> deleteDatabase(String databaseName,
      [DBDirConst? dirConst]) async {
    if (databaseName.isEmpty) {
      return;
    }
    if (!databaseName.endsWith(".db")) {
      databaseName = "$databaseName.db";
    }
    try {
      String dbFilePath =
          await StorageHelper.getDatabaseFilePath(databaseName, dirConst);
      File dbFile = File(dbFilePath);
      dbFile.deleteSync();
    } catch (exception) {
      Log.message("application delete db error: $exception");
    }
  }

  Future<void> deleteAllDatabase([DBDirConst? dirConst]) async {
    try {
      String dbDirPath = await StorageHelper.getDatabaseDirPath(dirConst);
      Directory dbDir = Directory(dbDirPath);
      List<FileSystemEntity> listFileSync = dbDir.listSync();
      for (FileSystemEntity fileEntity in listFileSync) {
        Log.message(
            "application deleteAllDatabase db file: ${fileEntity.path}");
        fileEntity.deleteSync();
      }
    } catch (exception) {
      Log.message("application deleteAllDatabase db error: $exception");
    }
  }
}
