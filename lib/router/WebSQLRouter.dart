import 'dart:convert';

import 'package:flutter_app/common/log/Log.dart';
import 'package:web_sqlite_test/database/DBManager.dart';

import 'RouterConstants.dart';

///websql://host?action=xxx&data={jsonData}
class WebSQLRouter {
  static void route(String webSqlRoute, {RouterCallback? callback}) {
    if (webSqlRoute.isEmpty) {
      Log.message("WebSQLRouter route is null");
      callback?.call("router is null");
      return;
    }
    if (!webSqlRoute.startsWith(RouterConstants.constScheme)) {
      Log.message("WebSQLRouter route scheme error");
      callback?.call("route scheme error");
      return;
    }
    Uri webSQLUri;
    try {
      webSQLUri = Uri.parse(webSqlRoute);
    } catch (error) {
      Log.message("WebSQLRouter route parse url error$error");
      callback?.call("route parse url error");
      return;
    }
    Map<String, String> parameters = webSQLUri.queryParameters;
    String? paramAction = parameters[RouterConstants.constParamAction];
    String? paramData = parameters[RouterConstants.constParamData];
    String? paramRouterId = parameters[RouterConstants.constParamRouterId];
    Log.message(
        "WebSQLRouter route parse url \n paramsAction: $paramAction \n paramsData: $paramData \n paramRouterId: $paramRouterId");
    _handleRouteAction(paramAction, paramData, paramRouterId, callback);
  }

  static void _handleRouteAction(String? paramAction, String? paramData,
      String? paramRouterId, RouterCallback? callback) {
    if (paramAction == null || paramAction.isEmpty) {
      Log.message("WebSQLRouter route paramAction is null");
      callback?.call("paramAction is null", paramRouterId);
      return;
    }
    checkParamDataNull() {
      if (paramData == null || paramData.isEmpty) {
        callback?.call("paramData is null", paramRouterId);
        return true;
      }
      return false;
    }

    Map<String, dynamic>? paramDataResult;
    switch (paramAction) {
      case RouterConstants.actionExecSQL:
        if (checkParamDataNull()) {
          return;
        }
        paramDataResult = jsonDecode(paramData!);
        String? databaseName = paramDataResult?["databaseName"];
        if (databaseName == null) {
          callback?.call("databaseName is null", paramRouterId);
          return;
        }
        String? sql = paramDataResult?['sql'];
        if (sql == null) {
          callback?.call("exec sql is null", paramRouterId);
          return;
        }
        List<dynamic>? sqlParams;
        try {
          sqlParams = paramDataResult?['sqlParams'] as List?;
        } catch (error) {
          Log.message("WebSQLRouter route sqlParams parse error");
        }
        DBManager.getInstance()
            .getDBCommandHelper(databaseName)
            .execSql(sql, sqlParams, (result) {
          callback?.call(result, paramRouterId);
        });
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
}

typedef RouterCallback = Function(String routerResult, [String? routerId]);
