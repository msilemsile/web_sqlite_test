import 'package:web_sqlite_test/database/DBManager.dart';

class JSInterface {
  ///创建数据库
  static void createDatabase(String databaseName) {
    var openDatabase = DBManager.getInstance().openDatabase(databaseName);
    openDatabase?.then((value) => value?.dispose());
  }

  ///删除数据库
  static void deleteDatabase(String databaseName) {
    DBManager.getInstance().deleteDatabase(databaseName);
  }

  ///执行sql数据语句
  static void execSQL(String databaseName, String sql) {
    DBManager.getInstance().execSQL(databaseName, sql);
  }
}
