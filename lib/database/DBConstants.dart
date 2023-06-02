import 'DBDirConst.dart';

abstract class DBConstants {
  ///本地数据库目录
  static const String dbLocalDirName = "LocalDB";

  ///局域网数据库目录
  static const String dbLanDirName = "lanDB";

  ///服务器数据库目录
  static const String dbServerDirName = "ServerDB";

  static Map<DBDirConst, String> dbDirConstMap = {
    DBDirConst.local: dbLocalDirName,
    DBDirConst.lan: dbLanDirName,
    DBDirConst.server: dbServerDirName
  };

  static String getDBDirTitle(DBDirConst dbDirConst) {
    String dbTitle = "临时数据";
    switch (dbDirConst) {
      case DBDirConst.local:
        dbTitle = "本地数据";
        break;
      case DBDirConst.lan:
        dbTitle = "局域网数据(只读)";
        break;
      case DBDirConst.server:
        dbTitle = "服务器数据(只读)";
        break;
    }
    return dbTitle;
  }
}
