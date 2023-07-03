import 'dart:convert';
import 'dart:io';

import 'package:web_sqlite_test/router/RouterManager.dart';

import '../model/DBFileInfo.dart';

abstract class RouterConstants {
  ///base
  static const String constScheme = "websql";
  static const String constHost = "host";
  static const String constParamAction = "action";
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
  static const String dataHost = "host";
  static const String dataPlatform = "platform";
  static const String dataResult = "result";
  static const String dataDBName = "dbName";
  static const String dataSQL = "sql";
  static const String dataSQLParams = "sqlParams";
  static const String dataShakeHands = "shakeHands";

  static const List<String> dataParams = [
    dataHost,
    dataPlatform,
    dataResult,
    dataDBName,
    dataSQL,
    dataSQLParams,
    dataShakeHands
  ];

  static String buildSocketBroadcastRoute(String wifiIP, [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionBroadcast,
        routerId,
        {dataHost: wifiIP, dataPlatform: Platform.operatingSystem});
    return webSQLRoute;
  }

  static String buildSocketConnectRoute(String wifiIP,
      [int shakeHands = 0, String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionConnect, routerId, {
      dataHost: wifiIP,
      dataPlatform: Platform.operatingSystem,
      dataShakeHands: shakeHands.toString()
    });
    return webSQLRoute;
  }

  static String buildListDBRoute([String? routerId]) {
    routerId ??= "0";
    String webSQLRoute =
        RouterManager.buildWebSQLRoute(RouterConstants.actionListDB, routerId);
    return webSQLRoute;
  }

  static String buildListDBResultRoute(List<DBFileInfo> dbFileList,
      [String? routerId]) {
    routerId ??= "0";
    String dbFileListJson = jsonEncode(dbFileList).toString();
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionListDBResult,
        routerId,
        {dataResult: dbFileListJson});
    return webSQLRoute;
  }

  static String buildCreateDBRoute(String dbName, [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionCreateDB, routerId, {dataDBName: dbName});
    return webSQLRoute;
  }

  static String buildCreateDBResultRoute(String dbName, int result,
      [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionCreateDBResult,
        routerId,
        {dataDBName: dbName, dataResult: result.toString()});
    return webSQLRoute;
  }

  static String buildDeleteDBRoute(String dbName, [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionDeleteDB, routerId, {dataDBName: dbName});
    return webSQLRoute;
  }

  static String buildDeleteDBResultRoute(String dbName, int result,
      [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionDeleteDBResult,
        routerId,
        {dataDBName: dbName, dataResult: result.toString()});
    return webSQLRoute;
  }

  static String buildExecSQLRoute(String dbName, String sql,
      [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionExecSQL,
        routerId,
        {dataDBName: dbName, dataSQL: sql});
    return webSQLRoute;
  }

  static String buildExecSQLResultRoute(String dbName, String result,
      [String? routerId]) {
    routerId ??= "0";
    var webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionExecSQLResult,
        routerId,
        {dataDBName: dbName, dataResult: result});
    return webSQLRoute;
  }

  static String buildDownloadDBRoute(String dbName, [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionDownloadDB, routerId, {dataDBName: dbName});
    return webSQLRoute;
  }

  static String buildDownloadDBResultRoute(String dbName, String result,
      [String? routerId]) {
    routerId ??= "0";
    String webSQLRoute = RouterManager.buildWebSQLRoute(
        RouterConstants.actionDownloadDBResult,
        routerId,
        {dataDBName: dbName, dataResult: result});
    return webSQLRoute;
  }
}
