import 'dart:io';

import 'package:flutter_app/flutter_app.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:web_sqlite_test/database/DBStorageHelper.dart';

import 'DBDirConst.dart';

class DBManager {
  DBManager._();

  static DBManager? _dbManager;

  static DBManager getInstance() {
    _dbManager ??= DBManager._();
    return _dbManager!;
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
          await DBStorageHelper.getDatabaseFilePath(databaseName, dirConst);
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
          await DBStorageHelper.getDatabaseFilePath(databaseName, dirConst);
      File dbFile = File(dbFilePath);
      dbFile.deleteSync();
    } catch (exception) {
      Log.message("application delete db error: $exception");
    }
  }

  Future<void> deleteAllDatabase([DBDirConst? dirConst]) async {
    try {
      String dbDirPath = await DBStorageHelper.getDatabaseDirPath(dirConst);
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
