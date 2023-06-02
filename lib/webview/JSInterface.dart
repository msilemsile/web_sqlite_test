import 'package:web_sqlite_test/database/ExecSqlResult.dart';

class JSInterface {
  ///打开数据库
  void openDatabase(String databaseName) {}

  ///断开数据库
  void disposeDatabase(String databaseName) {}

  ///创建数据库
  void createDatabase(String databaseName) {

  }

  ///执行sql数据语句
  static ExecSqlResult? execSQL(
      String databaseName, String sql, List<String> params) {
    return null;
  }
}
