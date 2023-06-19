import 'DBDirConst.dart';

abstract class DBConstants {
  ///本地数据库目录
  static const String dbLocalDirName = "LocalDB";

  ///局域网缓存数据库目录
  static const String dbCacheLanDirName = "LanDB";

  ///服务器缓存数据库目录
  static const String dbCacheServerDirName = "ServerDB";

  ///临时数据库目录
  static const String dbTempDirName = "TempDB";

  static Map<DBDirConst, String> dbDirConstMap = {
    DBDirConst.local: dbLocalDirName,
    DBDirConst.cacheLan: dbCacheLanDirName,
    DBDirConst.cacheServer: dbCacheServerDirName,
    DBDirConst.temp: dbTempDirName,
  };

  static String getDBDirTitle(DBDirConst dbDirConst) {
    String dbTitle = "本地临时";
    switch (dbDirConst) {
      case DBDirConst.local:
        dbTitle = "本地工作";
        break;
      case DBDirConst.cacheLan:
        dbTitle = "本地缓存(局域网)";
        break;
      case DBDirConst.cacheServer:
        dbTitle = "本地缓存(服务器)";
        break;
      case DBDirConst.lan:
        dbTitle = "局域网";
        break;
      case DBDirConst.server:
        dbTitle = "服务器";
        break;
      case DBDirConst.temp:
        dbTitle = "本地临时";
        break;
    }
    return dbTitle;
  }
}
