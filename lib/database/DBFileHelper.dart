import 'dart:io';

import 'package:flutter_app/flutter_app.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:web_sqlite_test/utils/StorageHelper.dart';

import 'DBDirConst.dart';

abstract class DBFileHelper {

  static Future<bool> isDatabaseExist(String? databaseName,
      [DBDirConst? dirConst]) async {
    try {
      if (databaseName == null || databaseName.isEmpty) {
        return false;
      }
      if (!databaseName.endsWith(".db")) {
        databaseName = "$databaseName.db";
      }
      String dbFilePath =
      await StorageHelper.getDatabaseFilePath(databaseName, dirConst);
      File dbFile = File(dbFilePath);
      return dbFile.exists();
    } catch (exception) {
      Log.message("application create db error: $exception");
    }
    return false;
  }

  static Future<Database?>? openDatabase(String? databaseName,
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

  static Future<void> deleteDatabase(String databaseName,
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
}
