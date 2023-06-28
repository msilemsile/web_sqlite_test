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
  static const String actionBroadcast = "broadcast";
  static const String actionListDB = "listDB";
  static const String actionListDBResult = "listDBResult";
  static const String actionCreateDB = "createDB";
  static const String actionCreateDBResult = "createDBResult";
  static const String actionDeleteDB = "deleteDB";
  static const String actionDeleteDBResult = "deleteDBResult";
  static const String actionExecSQL = "execSQL";
  static const String actionExecSQLResult = "execSQLResult";
  static const String actionDownloadDB = "downloadDB";
  static const String actionDownloadDBResult = "downloadDBResult";

  ///param data
  static const String dataRouterId = "routerId";
  static const String dataHost = "host";
  static const String dataPlatform = "platform";
  static const String dataResult = "result";
  static const String dataDBName = "dbName";
  static const String dataSQL = "sql";
  static const String dataSQLParams = "sqlParams";
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

  static String buildListDBRoute([String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionListDB, {dataRouterId: routerId});
    return webSQLRoute;
  }

  static String buildListDBResultRoute(List<DBFileInfo> dbFileList,
      [String? routerId]) {
    routerId ??= "0";
    String dbFileListJson = jsonEncode(dbFileList).toString();
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionListDBResult,
        {dataResult: dbFileListJson, dataRouterId: routerId});
    return webSQLRoute;
  }

  static String buildCreateDBRoute(String dbName, [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionCreateDB,
        {dataDBName: dbName, dataRouterId: routerId});
    return webSQLRoute;
  }

  static String buildCreateDBResultRoute(String dbName, int result,
      [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionCreateDBResult, {
      dataDBName: dbName,
      dataResult: result.toString(),
      dataRouterId: routerId
    });
    return webSQLRoute;
  }

  static String buildDeleteDBRoute(String dbName, [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionDeleteDB,
        {dataDBName: dbName, dataRouterId: routerId});
    return webSQLRoute;
  }

  static String buildDeleteDBResultRoute(String dbName, int result,
      [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionDeleteDBResult, {
      dataDBName: dbName,
      dataResult: result.toString(),
      dataRouterId: routerId
    });
    return webSQLRoute;
  }

  static String buildExecSQLRoute(String dbName, String sql,
      [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionExecSQL,
        {dataDBName: dbName, dataSQL: sql, dataRouterId: routerId});
    return webSQLRoute;
  }

  static String buildExecSQLResultRoute(String dbName, String result,
      [String? routerId]) {
    routerId ??= "0";
    var webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionExecSQLResult,
        {dataDBName: dbName, dataResult: result, dataRouterId: routerId});
    return webSQLRoute;
  }

  static String buildDownloadDBRoute(String dbName, [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionDownloadDB,
        {dataDBName: dbName, dataRouterId: routerId});
    return webSQLRoute;
  }

  static String buildDownloadDBResultRoute(String dbName, String result,
      [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionDownloadDBResult,
        {dataDBName: dbName, dataResult: result, dataRouterId: routerId});
    return webSQLRoute;
  }
}
