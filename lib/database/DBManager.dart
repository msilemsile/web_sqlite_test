import 'dart:io';

import 'package:flutter_app/flutter_app.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:web_sqlite_test/database/DBConstants.dart';
import 'package:web_sqlite_test/database/ExecSqlResult.dart';
import 'package:web_sqlite_test/model/DBFileInfo.dart';

class DBManager {
  DBManager._();

  static DBManager? _dbManager;

  static DBManager getInstance() {
    _dbManager ??= DBManager._();
    return _dbManager!;
  }

  DBDirConst currentDBDir = DBDirConst.local;

  Future<List<DBFileInfo>> listWorkspaceDBFile([DBDirConst? dirConst]) async {
    String dbDirPath = await getDatabaseDirPath(dirConst);
    Directory dbDir = Directory(dbDirPath);
    List<FileSystemEntity> listFileSync = dbDir.listSync();
    List<DBFileInfo> dbFileInfoList = [];
    for (FileSystemEntity fileEntity in listFileSync) {
      String filePath = fileEntity.path;
      Log.message("application listWorkspaceDBFile : $filePath");
      String fileExtension = p.extension(filePath);
      String fileName = p.basenameWithoutExtension(filePath);
      if (fileExtension.contains(".db")) {
        dbFileInfoList.add(DBFileInfo(fileName, filePath));
      }
    }
    return dbFileInfoList;
  }

  Future<String> getDatabaseDirPath([DBDirConst? dirConst]) async {
    //创建数据库文件夹
    //获取应用数据目录
    Directory rootDirectory = await getApplicationSupportDirectory();
    String rootPath = rootDirectory.absolute.path;
    Log.message("application root dir : $rootPath");
    //创建数据库根目录
    dirConst ??= currentDBDir;
    String? dbDirName = DBConstants.dbDirConstMap[dirConst];
    if (dbDirName == null) {
      return "";
    }
    Directory dbDir = Directory(p.join(rootPath, dbDirName));
    bool dbDirExists = await dbDir.exists();
    if (dbDirExists) {
      Log.message("application db dir exits!");
    } else {
      dbDir.createSync();
      Log.message("application create db dir : ${dbDir.absolute.path}");
    }
    return dbDir.path;
  }

  Future<String> getDatabaseFilePath(String dbFileName,
      [DBDirConst? dirConst]) async {
    String dbDirPath = await getDatabaseDirPath(dirConst);
    return p.join(dbDirPath, dbFileName);
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
      String dbFilePath = await getDatabaseFilePath(databaseName, dirConst);
      File dbFile = File(dbFilePath);
      dbFile.deleteSync();
    } catch (exception) {
      Log.message("application delete db error: $exception");
    }
  }

  Future<void> deleteAllDatabase([DBDirConst? dirConst]) async {
    try {
      String dbDirPath = await getDatabaseDirPath(dirConst);
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

  Future<Database?>? openDatabase(String? databaseName,
      [DBDirConst? dirConst]) async {
    try {
      if (databaseName == null || databaseName.isEmpty) {
        return null;
      }
      if (!databaseName.endsWith(".db")) {
        databaseName = "$databaseName.db";
      }
      String dbFilePath = await getDatabaseFilePath(databaseName, dirConst);
      Log.message("application create db file : $dbFilePath");
      Database database = sqlite3.open(dbFilePath);
      return database;
    } catch (exception) {
      Log.message("application create db error: $exception");
    }
    return null;
  }

  Future<ExecSqlResult> execSQLWithResult(String databaseName, String sql,
      [DBDirConst? dirConst]) async {
    if (databaseName.isEmpty) {
      return ExecSqlResult.newErrorResult("数据库名称为空");
    }
    if (!databaseName.endsWith(".db")) {
      databaseName = "$databaseName.db";
    }
    Database? database;
    try {
      database = await openDatabase(databaseName, dirConst);
      ResultSet? resultSet = database?.select(sql);
      return ExecSqlResult.newSuccessResult(resultSet?.toString());
    } catch (exception) {
      Log.message("application execSQL error: $exception");
      return ExecSqlResult.newErrorResult(exception.toString());
    } finally {
      database?.dispose();
    }
  }

  Future<ExecSqlResult> execSQL(String databaseName, String sql,
      [DBDirConst? dirConst]) async {
    if (databaseName.isEmpty) {
      return ExecSqlResult.newErrorResult("数据库名称为空");
    }
    if (!databaseName.endsWith(".db")) {
      databaseName = "$databaseName.db";
    }
    Database? database;
    try {
      database = await openDatabase(databaseName, dirConst);
      database?.execute(sql);
      return ExecSqlResult.newSuccessResult(null);
    } catch (exception) {
      Log.message("application execSQL error: $exception");
      return ExecSqlResult.newErrorResult(exception.toString());
    } finally {
      database?.dispose();
    }
  }
}

enum DBDirConst {
  local,
  lan,
  server,
}
