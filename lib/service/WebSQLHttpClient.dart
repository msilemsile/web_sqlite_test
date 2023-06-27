import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/common/log/Log.dart';
import 'package:flutter_app/common/widget/AppToast.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';
import 'package:web_sqlite_test/service/WebSQLHttpServer.dart';

import '../model/DBFileInfo.dart';
import '../router/WebSQLRouterCallback.dart';

class WebSQLHttpClient {
  WebSQLHttpClient._();

  static WebSQLHttpClient? _instance;

  static WebSQLHttpClient getInstance() {
    _instance ??= WebSQLHttpClient._();
    return _instance!;
  }

  HostInfo? _connectHostInfo;
  HttpClient? _httpClient;
  final Set<WebSQLRouterCallback> _webSQLCallbackSet = {};

  void connect(HostInfo hostInfo) {
    _httpClient = HttpClient();
    _httpClient?.connectionTimeout = const Duration(seconds: 5);
    _connectHostInfo = hostInfo;
    Log.message("WebSQLHttpClient connect hostInfo : $hostInfo");
  }

  void openOrCreateDB(String databaseName, String routerId) {
    if (_connectHostInfo == null) {
      AppToast.show("主机为空!");
      return;
    }
    Map<String, String> originDataParams = {
      RouterConstants.dataDBName: databaseName,
    };
    _getHttpWebSQLRequest(
        RouterConstants.actionCreateDB, originDataParams, routerId);
  }

  void deleteDB(String databaseName, String routerId) {
    if (_connectHostInfo == null) {
      AppToast.show("主机为空!");
      return;
    }
    Map<String, String> originDataParams = {
      RouterConstants.dataDBName: databaseName,
    };
    _getHttpWebSQLRequest(
        RouterConstants.actionDeleteDB, originDataParams, routerId);
  }

  void listDB(String routerId) {
    if (_connectHostInfo == null) {
      AppToast.show("主机为空!");
      return;
    }
    _getHttpWebSQLRequest(RouterConstants.actionListDB, null, routerId);
  }

  void execSQL(String databaseName, String sql, String routerId) {
    if (_connectHostInfo == null) {
      AppToast.show("主机为空!");
      return;
    }
    Map<String, String> originDataParams = {
      RouterConstants.dataDBName: databaseName,
      RouterConstants.dataSQL: sql
    };
    _getHttpWebSQLRequest(
        RouterConstants.actionExecSQL, originDataParams, routerId);
  }

  void _getHttpWebSQLRequest(String actionParams,
      Map<String, String>? dataParams, String routerId) async {
    if (_connectHostInfo == null) {
      AppToast.show("主机为空!");
      return;
    }
    Log.message(
        "WebSQLHttpClient _getHttpWebSQLRequest action : $actionParams dataParams : $dataParams");
    Map<String, String> queryParameters = {};
    queryParameters.addAll({"action": actionParams});
    if (dataParams != null && dataParams.isNotEmpty) {
      queryParameters
          .addAll({"data": Uri.encodeComponent(jsonEncode(dataParams))});
    }
    Uri uri = Uri(
        scheme: "http",
        host: _connectHostInfo!.host,
        port: WebSQLHttpServer.httpServerListenPort,
        queryParameters: queryParameters);
    _httpClient?.getUrl(uri).then((httpClientRequest) {
      httpClientRequest.close().then((httpClientResponse) {
        httpClientResponse.transform(utf8.decoder).join().then((result) {
          Log.message(
              "WebSQLHttpClient _getHttpWebSQLRequest result : $result");
          switch (actionParams) {
            case RouterConstants.actionCreateDB:
              for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
                callback.onOpenOrCreateDB(result, routerId);
              }
              break;
            case RouterConstants.actionDeleteDB:
              for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
                callback.onDeleteDB(result, routerId);
              }
              break;
            case RouterConstants.actionListDB:
              List<DBFileInfo> dbFileList = [];
              List<dynamic> jsonList = jsonDecode(result);
              for (Map<String, dynamic> object in jsonList) {
                DBFileInfo dbFileInfo = DBFileInfo.fromJson(object);
                dbFileList.add(dbFileInfo);
              }
              for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
                callback.onListDBFile(dbFileList, routerId);
              }
              break;
            case RouterConstants.actionExecSQL:
              for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
                callback.onExecSQLResult(result, routerId);
              }
              break;
          }
        });
      });
    });
  }

  void addWebRouterCallback(WebSQLRouterCallback callback) {
    _webSQLCallbackSet.add(callback);
  }

  void removeWebRouterCallback(WebSQLRouterCallback? callback) {
    _webSQLCallbackSet.remove(callback);
  }

  void destroy() {
    Log.message("WebSQLHttpClient--destroy");
    _connectHostInfo = null;
    _webSQLCallbackSet.clear();
    _httpClient?.close(force: true);
    _httpClient = null;
  }
}
