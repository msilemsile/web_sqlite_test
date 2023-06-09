import 'dart:convert';

import 'package:flutter_app/common/log/Log.dart';
import 'package:web_sqlite_test/database/DBDirConst.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/model/WebSQLRouter.dart';

import 'RouterConstants.dart';

///websql://host?action=xxx&routerId=xxx&dataKey=dataValue
class RouterManager {
  static void route(String routerString, {RouterCallback? callback}) {
    if (routerString.isEmpty) {
      Log.message("WebSQLRouter route is null");
      callback?.call("router is null");
      return;
    }
    WebSQLRouter? webSQLRouter = parseToWebSQLRouter(routerString);
    if (webSQLRouter == null) {
      callback?.call("WebSQLRouter parseToWebSQLRouter error");
      return;
    }
    handleRouteAction(webSQLRouter, callback);
  }

  static void handleRouteAction(
      WebSQLRouter webSQLRouter, RouterCallback? callback,
      [DBDirConst? dbDirConst]) {
    Log.message("WebSQLRouter route parse url $webSQLRouter");
    String? paramAction = webSQLRouter.action;
    String? paramRouterId = webSQLRouter.routerId;
    Map<String, dynamic>? paramDataResult = webSQLRouter.jsonData;
    if (paramAction == null || paramAction.isEmpty) {
      Log.message("WebSQLRouter route paramAction is null");
      callback?.call("paramAction is null", paramRouterId);
      return;
    }

    switch (paramAction) {
      case RouterConstants.actionListDB:
        DBWorkspaceManager.getInstance().listWorkspaceDBFile((dbFileList) {
          String dbFileListJson = jsonEncode(dbFileList).toString();
          callback?.call(dbFileListJson, paramRouterId);
        }, dbDirConst);
        break;
      case RouterConstants.actionCreateDB:
        if (paramDataResult == null) {
          return;
        }
        String? databaseName = paramDataResult[RouterConstants.dataDBName];
        if (databaseName == null) {
          callback?.call("databaseName is null", paramRouterId);
          return;
        }
        DBWorkspaceManager.getInstance().openOrCreateWorkspaceDB(databaseName,
            (result) {
          callback?.call(result, paramRouterId);
        }, dbDirConst);
        break;
      case RouterConstants.actionDeleteDB:
        if (paramDataResult == null) {
          return;
        }
        String? databaseName = paramDataResult[RouterConstants.dataDBName];
        if (databaseName == null) {
          callback?.call("databaseName is null", paramRouterId);
          return;
        }
        DBWorkspaceManager.getInstance().deleteWorkspaceDB(databaseName,
            (result) {
          callback?.call(result, paramRouterId);
        }, dbDirConst);
        break;
      case RouterConstants.actionExecSQL:
        if (paramDataResult == null) {
          return;
        }
        String? databaseName = paramDataResult[RouterConstants.dataDBName];
        if (databaseName == null) {
          callback?.call("databaseName is null", paramRouterId);
          return;
        }
        String? sql = paramDataResult[RouterConstants.dataSQL];
        if (sql == null) {
          callback?.call("exec sql is null", paramRouterId);
          return;
        }
        List<dynamic>? sqlParams;
        try {
          sqlParams = paramDataResult[RouterConstants.dataSQLParams] as List?;
        } catch (error) {
          Log.message("WebSQLRouter route sqlParams parse error");
        }
        DBWorkspaceManager.getInstance().execSql(databaseName, sql, sqlParams,
            (result) {
          callback?.call(result, paramRouterId);
        }, dbDirConst);
        break;
    }
  }

  static String buildWebSQLRoute(String actionName, String routerId,
      [Map<String, String>? paramsMap = const {}]) {
    Map<String, String> webSQLParams = {};
    webSQLParams[RouterConstants.constParamAction] = actionName;
    webSQLParams[RouterConstants.constParamRouterId] =
        Uri.encodeComponent(routerId);
    if (paramsMap != null) {
      paramsMap.forEach((key, value) {
        webSQLParams[key] = Uri.encodeComponent(value);
      });
    }
    Uri uri = Uri(
        scheme: RouterConstants.constScheme,
        host: RouterConstants.constHost,
        queryParameters: webSQLParams);
    return uri.toString();
  }

  static WebSQLRouter? parseToWebSQLRouter(String routerString) {
    if (!routerString.startsWith(RouterConstants.constScheme)) {
      return null;
    }
    Uri webSQLUri;
    try {
      webSQLUri = Uri.parse(routerString);
    } catch (error) {
      Log.message("WebSQLRouter route parse url error$error");
      return null;
    }
    Map<String, String> parameters = webSQLUri.queryParameters;
    return convertWebSQLRouter(parameters);
  }

  static WebSQLRouter? convertWebSQLRouter(Map<String, String> parameters) {
    String? paramAction = parameters[RouterConstants.constParamAction];
    String? paramRouterId = "0";
    String? routerIdValue = parameters[RouterConstants.constParamRouterId];
    if (routerIdValue != null) {
      paramRouterId = Uri.decodeComponent(routerIdValue);
    }
    Map<String, dynamic> jsonData = {};
    parameters.forEach((key, value) {
      if (key.compareTo(RouterConstants.constParamAction) == 0 ||
          key.compareTo(RouterConstants.constParamRouterId) == 0) {
        return;
      }
      jsonData[key] = Uri.decodeComponent(value);
    });
    WebSQLRouter webSQLRouter =
        WebSQLRouter(paramAction, jsonData, paramRouterId);
    return webSQLRouter;
  }

  static String buildTempRouterId([String tag = "routerId"]) {
    return "$tag:${DateTime.now().millisecondsSinceEpoch}";
  }
}

typedef RouterCallback = Function(String routerResult, [String? routerId]);
