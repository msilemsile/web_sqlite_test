import 'dart:convert';
import 'dart:io';

import 'package:web_sqlite_test/router/RouterManager.dart';

import '../model/DBFileInfo.dart';

abstract class RouterConstants {
  ///base
  static const String constScheme = "websql";
  static const String constHost = "host";
  static const String constParamAction = "action";
  static const String constParamData = "data";
  static const String constParamRouterId = "routerId";

  ///param action
  static const String actionConnect = "connect";
  static const String actionUnConnect = "unConnect";
  static const String actionBroadcast = "broadcast";
  static const String actionListDB = "listDB";
  static const String actionListDBResult = "listDBResult";
  static const String actionCreateDB = "createDB";
  static const String actionCreateDBResult = "createDBResult";
  static const String actionDeleteDB = "deleteDB";
  static const String actionDeleteDBResult = "deleteDBResult";
  static const String actionExecSQL = "execSQL";
  static const String actionExecSQLResult = "execSQLResult";

  ///param data
  static const String dataHost = "host";
  static const String dataPlatform = "platform";
  static const String dataResult = "result";
  static const String dataDBName = "dbName";
  static const String dataSQL = "sql";
  static const String dataShakeHands = "shakeHands";

  static String buildSocketBroadcastRoute(String wifiIP) {
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionBroadcast,
        {dataHost: wifiIP, dataPlatform: Platform.operatingSystem});
    return webSQLRoute;
  }

  static String buildSocketConnectRoute(String wifiIP, [int shakeHands = 0]) {
    String webSQLRoute =
        RouterManager.buildWebSQLRoute(RouterConstants.actionConnect, {
      dataHost: wifiIP,
      dataPlatform: Platform.operatingSystem,
      dataShakeHands: shakeHands.toString()
    });
    return webSQLRoute;
  }

  static String buildSocketUnConnectRoute(String wifiIP) {
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionUnConnect,
        {dataHost: wifiIP, dataPlatform: Platform.operatingSystem});
    return webSQLRoute;
  }

  static String buildListDBRoute() {
    String webSQLRoute =
        RouterManager.buildWebSQLRoute(RouterConstants.actionListDB);
    return webSQLRoute;
  }

  static String buildListDBResultRoute(List<DBFileInfo> dbFileList) {
    String dbFileListJson = jsonEncode(dbFileList).toString();
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionListDBResult, {dataResult: dbFileListJson});
    return webSQLRoute;
  }

  static String buildCreateDBRoute(String dbName) {
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionCreateDB, {dataDBName: dbName});
    return webSQLRoute;
  }

  static String buildCreateDBResultRoute(String dbName, int result) {
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionCreateDBResult,
        {dataDBName: dbName, dataResult: result.toString()});
    return webSQLRoute;
  }

  static String buildDeleteDBRoute(String dbName) {
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionDeleteDB, {dataDBName: dbName});
    return webSQLRoute;
  }

  static String buildDeleteDBResultRoute(String dbName, int result) {
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionDeleteDBResult,
        {dataDBName: dbName, dataResult: result.toString()});
    return webSQLRoute;
  }

  static String buildExecSQLRoute(String dbName, String sql) {
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionExecSQL, {dataDBName: dbName, dataSQL: sql});
    return webSQLRoute;
  }

  static String buildExecSQLResultRoute(String dbName, String result) {
    var webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionExecSQLResult,
        {dataDBName: dbName, dataResult: result});
    return webSQLRoute;
  }
}
