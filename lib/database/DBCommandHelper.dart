import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';

typedef OnExecSqlCallback = Function(String execSqlResult);

class DBCommandHelper {
  late String _databaseName;
  Database? _database;

  DBCommandHelper._();

  static DBCommandHelper builder(String databaseName) {
    DBCommandHelper dbCommandHelper = DBCommandHelper._();
    dbCommandHelper._databaseName = databaseName;
    return dbCommandHelper;
  }

  String getDatabaseName() {
    return _databaseName;
  }

  Future<DBCommandHelper> execSql(String sql,
      [List<dynamic>? parameters, OnExecSqlCallback? sqlCallback]) async{
    _database ??= await DBWorkspaceManager.getInstance().openOrCreateWorkspaceDB(_databaseName);
    try {
      parameters ??= const [];
      ResultSet? resultSet = _database?.select(sql, parameters);
      sqlCallback?.call(resultSet.toString());
    } catch (error) {
      sqlCallback?.call(error.toString());
    }
    return this;
  }

  void disposeDatabase() {
    _database?.dispose();
    _database = null;
  }

  static void showExecSqlResult(BuildContext context, String execSqlResult) {
    AppAlertDialog.builder()
        .setTitle("执行结果")
        .setContent(execSqlResult)
        .setCancelTxt("复制")
        .setCancelCallback((alertDialog) {
      Clipboard.setData(ClipboardData(text: execSqlResult));
      AppToast.show("复制成功");
    }).show(context);
  }
}
