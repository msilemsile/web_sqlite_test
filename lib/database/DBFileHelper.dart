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

  static Future<void> renameDBTempFile(String databaseName,
      [DBDirConst? dirConst]) async {
    try {
      String dbTempFilePath =
          await StorageHelper.getDatabaseFilePath("$databaseName.temp", dirConst);
      File dbTempFile = File(dbTempFilePath);
      bool exists = await dbTempFile.exists();
      if(!exists){
        Log.message(
            "application renameDBTempFile db $databaseName error: temp file is not exist");
        return;
      }
      int lastSeparator = dbTempFilePath.lastIndexOf(Platform.pathSeparator);
      String newDBPath =
          "${dbTempFilePath.substring(0, lastSeparator + 1)}$databaseName.db";
      File dbFile = await dbTempFile.rename(newDBPath);
      Log.message(
          "application renameDBTempFile db $databaseName success file Path: ${dbFile.path}");
    } catch (exception) {
      Log.message(
          "application renameDBTempFile db $databaseName error: $exception");
    }
  }

  static Future<File?> createDBTempFile(String databaseName,
      [DBDirConst? dirConst]) async {
    if (databaseName.isEmpty) {
      return null;
    }
    try {
      String dbFilePath =
          await StorageHelper.getDatabaseFilePath("$databaseName.temp", dirConst);
      File dbFile = File(dbFilePath);
      bool exist = await dbFile.exists();
      if (exist) {
        Log.message(
            "application createDBTempFile db $databaseName exist delete file");
        dbFile.deleteSync();
      }
      Log.message(
          "application createDBTempFile db $databaseName success path: $dbFilePath");
      return dbFile;
    } catch (exception) {
      Log.message(
          "application createDBTempFile db $databaseName error: $exception");
    }
    return null;
  }

  static Future<RandomAccessFile?> openDBRandomAccessFile(String databaseName,
      [DBDirConst? dirConst]) async {
    if (databaseName.isEmpty) {
      return null;
    }
    if (!databaseName.endsWith(".db")) {
      databaseName = "$databaseName.db";
    }
    try {
      String dbFilePath =
          await StorageHelper.getDatabaseFilePath(databaseName, dirConst);
      File dbFile = File(dbFilePath);
      bool exist = await dbFile.exists();
      if (!exist) {
        Log.message(
            "application openDBAccessFile db $databaseName error: file not exist");
        return null;
      }
      Log.message("application openDBAccessFile db $databaseName success");
      return dbFile.open();
    } catch (exception) {
      Log.message(
          "application openDBAccessFile db $databaseName error: $exception");
    }
    return null;
  }
}
