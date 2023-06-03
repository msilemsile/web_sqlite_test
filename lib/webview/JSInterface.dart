import 'package:web_sqlite_test/database/DBCommandHelper.dart';
import 'package:web_sqlite_test/database/DBManager.dart';

class JSInterface {

  ///打开数据库
  void openOrCreateDatabase(String databaseName) async {
    await DBManager.getInstance()
        .getDBCommandHelper(databaseName)
        .openDatabase();
  }

  ///执行sql数据语句
  void execSQL(String databaseName, String sql,
      {List<String> params = const [], OnExecSqlCallback? execSqlCallback}) {
    DBManager.getInstance()
        .getDBCommandHelper(databaseName)
        .execSql(sql, params, execSqlCallback);
  }

  ///断开数据库
  void disposeDatabase(String databaseName) {
    DBManager.getInstance().getDBCommandHelper(databaseName).disposeDatabase();
  }

}
