import 'dart:io';

import 'package:flutter_app/flutter_app.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';

import '../database/DBConstants.dart';
import '../database/DBDirConst.dart';

class StorageHelper {
  static Future<String> getHomeWebFilePath() async {
    //获取应用数据目录
    Directory rootDirectory = await getApplicationSupportDirectory();
    String rootPath = rootDirectory.absolute.path;
    Log.message("application root dir : $rootPath");
    String offlineDirName = "offline";
    Directory homeDir = Directory(p.join(rootPath, offlineDirName));
    bool dbDirExists = await homeDir.exists();
    if (dbDirExists) {
      Log.message("application db dir exits!");
    } else {
      homeDir.createSync();
      Log.message("application create db dir : ${homeDir.absolute.path}");
    }
    return p.join(homeDir.path, "home.html");
  }

  static Future<String> getDatabaseDirPath([DBDirConst? dirConst]) async {
    //创建数据库文件夹
    //获取应用数据目录
    Directory rootDirectory = await getApplicationSupportDirectory();
    String rootPath = rootDirectory.absolute.path;
    Log.message("application root dir : $rootPath");
    //创建数据库根目录
    dirConst ??= DBWorkspaceManager.getInstance().getCurrentDBDir();
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

  static Future<String> getDatabaseFilePath(String dbFileName,
      [DBDirConst? dirConst]) async {
    String dbDirPath = await getDatabaseDirPath(dirConst);
    return p.join(dbDirPath, dbFileName);
  }
}
