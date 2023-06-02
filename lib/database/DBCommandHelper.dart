import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:web_sqlite_test/database/DBManager.dart';
import 'package:web_sqlite_test/database/ExecSqlResult.dart';
import 'package:web_sqlite_test/model/DBFileInfo.dart';

typedef OnExecSqlCallback = Function(ExecSqlResult execSqlResult);

class DBCommandHelper {
  late DBFileInfo _dbFileInfo;
  Database? _database;

  DBCommandHelper._();

  static DBCommandHelper builder(DBFileInfo dbFileInfo) {
    DBCommandHelper dbCommandHelper = DBCommandHelper._();
    dbCommandHelper._dbFileInfo = dbFileInfo;
    return dbCommandHelper;
  }

  DBFileInfo getDbFileInfo() {
    return _dbFileInfo;
  }

  Future<DBCommandHelper> openDatabase() async {
    _database ??=
        await DBManager.getInstance().openDatabase(_dbFileInfo.dbFileName);
    return this;
  }

  DBCommandHelper execSql(String sql,
      [List<Object?> parameters = const [], OnExecSqlCallback? sqlCallback]) {
    if (_database == null) {
      sqlCallback?.call(ExecSqlResult.newErrorResult(
          "database is null || open database error"));
      return this;
    }
    try {
      ResultSet? resultSet = _database?.select(sql, parameters);
      sqlCallback?.call(ExecSqlResult.newSuccessResult(resultSet.toString()));
    } catch (error) {
      sqlCallback?.call(ExecSqlResult.newErrorResult(error.toString()));
    }
    return this;
  }

  void disposeDatabase() {
    _database?.dispose();
  }

  static void showExecSqlResult(
      BuildContext context, ExecSqlResult execSqlResult) {
    String data = execSqlResult.data.toString();
    AppAlertDialog.builder()
        .setTitle(execSqlResult.code == 0 ? "执行成功" : "执行失败")
        .setContent(data)
        .setCancelTxt("复制")
        .setCancelCallback((alertDialog) {
      Clipboard.setData(ClipboardData(text: data));
      Toast.show(context, "复制成功");
    }).show(context);
  }
}
