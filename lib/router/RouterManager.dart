import 'dart:convert';

import 'package:flutter_app/common/log/Log.dart';
import 'package:web_sqlite_test/database/DBDirConst.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/model/WebSQLRouter.dart';

import 'RouterConstants.dart';

///websql://host?action=xxx&data={jsonData}
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
    Log.message("WebSQLRouter route parse url $webSQLRouter");
    handleRouteAction(webSQLRouter, callback);
  }

  static void handleRouteAction(
      WebSQLRouter webSQLRouter, RouterCallback? callback,
      [DBDirConst? dbDirConst]) {
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
        String? databaseName = paramDataResult["databaseName"];
        if (databaseName == null) {
          callback?.call("databaseName is null", paramRouterId);
          return;
        }
        DBWorkspaceManager.getInstance().openOrCreateWorkspaceDB(databaseName,
            (result) {
          if (result.compareTo("1") == 0) {
            callback?.call("创建$databaseName数据库成功");
          } else {
            callback?.call("创建$databaseName数据库失败!");
          }
        }, dbDirConst);
        break;
      case RouterConstants.actionDeleteDB:
        if (paramDataResult == null) {
          return;
        }
        String? databaseName = paramDataResult["databaseName"];
        if (databaseName == null) {
          callback?.call("databaseName is null", paramRouterId);
          return;
        }
        DBWorkspaceManager.getInstance().deleteWorkspaceDB(databaseName,
            (result) {
          if (result.compareTo("1") == 0) {
            callback?.call("删除$databaseName数据库成功");
          } else {
            callback?.call("删除$databaseName数据库失败!");
          }
        }, dbDirConst);
        break;
      case RouterConstants.actionExecSQL:
        if (paramDataResult == null) {
          return;
        }
        String? databaseName = paramDataResult["databaseName"];
        if (databaseName == null) {
          callback?.call("databaseName is null", paramRouterId);
          return;
        }
        String? sql = paramDataResult['sql'];
        if (sql == null) {
          callback?.call("exec sql is null", paramRouterId);
          return;
        }
        List<dynamic>? sqlParams;
        try {
          sqlParams = paramDataResult['sqlParams'] as List?;
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

  static String buildWebSQLRoute(String actionName,
      [Map<String, String>? paramsMap = const {}]) {
    String jsonData = json.encode(paramsMap).toString();
    Uri uri = Uri(
        scheme: RouterConstants.constScheme,
        host: RouterConstants.constHost,
        queryParameters: {
          RouterConstants.constParamAction: actionName,
          RouterConstants.constParamData: Uri.encodeComponent(jsonData)
        });
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
    String? paramData = parameters[RouterConstants.constParamData];
    Map<String, dynamic> jsonData = {};
    if (paramData != null) {
      jsonData = jsonDecode(Uri.decodeComponent(paramData));
    }
    String? paramRouterId = parameters[RouterConstants.constParamRouterId];
    return WebSQLRouter(paramAction, jsonData, paramRouterId);
  }

  static String buildTempRouterId([String tag = "routerId"]) {
    return "$tag:${DateTime.now().millisecondsSinceEpoch}";
  }
}

typedef RouterCallback = Function(String routerResult, [String? routerId]);
