import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/common/log/Log.dart';
import 'package:flutter_app/common/widget/AppToast.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';
import 'package:web_sqlite_test/service/WebSQLHttpServer.dart';

import '../database/DBFileHelper.dart';
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
  String? _downloadDatabaseName;
  String? _downloadDBRouterId;
  File? _downloadDBFile;
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

  void downloadDB(String dbName, String routerId) {
    if (_connectHostInfo == null) {
      AppToast.show("主机为空!");
      return;
    }
    Map<String, String> originDataParams = {
      RouterConstants.dataDBName: dbName,
    };
    _getHttpWebSQLRequest(
        RouterConstants.actionDownloadDB, originDataParams, routerId);
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

  Future<void> setDownloadDBFileInfo(
      String databaseName, String downloadRouterId) async {
    _downloadDatabaseName = databaseName;
    _downloadDBRouterId = downloadRouterId;
    _downloadDBFile = await DBFileHelper.createDBTempFile(databaseName);
  }

  Future<void> onDownloadDBFileResult(String result, String routerId) async {
    Log.message(
        "WebSQLHttpClient onDownloadDBFileResult result: $result routerId: $routerId");
    if (_downloadDatabaseName != null) {
      await DBFileHelper.renameDBTempFile(_downloadDatabaseName!);
      for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
        callback.onDownLoadDBResult(_downloadDatabaseName!, result, routerId);
      }
    }
    clearDownloadCache();
  }

  void _getHttpWebSQLRequest(
      String actionParams, Map<String, String>? dataParams, String routerId) {
    if (_connectHostInfo == null) {
      AppToast.show("主机为空!");
      return;
    }
    Log.message(
        "WebSQLHttpClient _getHttpWebSQLRequest action : $actionParams dataParams : $dataParams");
    Map<String, String> queryParameters = {};
    queryParameters.addAll({RouterConstants.constParamAction: actionParams});
    queryParameters.addAll({RouterConstants.constParamRouterId: routerId});
    if (dataParams != null && dataParams.isNotEmpty) {
      dataParams.forEach((key, value) {
        queryParameters[key] = Uri.encodeComponent(value);
      });
    }
    Uri uri = Uri(
        scheme: "http",
        host: _connectHostInfo!.host,
        port: WebSQLHttpServer.httpServerListenPort,
        queryParameters: queryParameters);
    _httpClient?.getUrl(uri).then((httpClientRequest) {
      httpClientRequest.close().then((HttpClientResponse httpClientResponse) {
        if (actionParams.compareTo(RouterConstants.actionDownloadDB) == 0 &&
            _downloadDatabaseName != null) {
          Log.message(
              "WebSQLHttpClient _getHttpWebSQLRequest start write _downloadDatabaseName : $_downloadDatabaseName header: ${httpClientResponse.headers}");
          IOSink? ioSink = _downloadDBFile?.openWrite();
          httpClientResponse.listen((event) {
            if (ioSink != null) {
              Log.message(
                  "WebSQLHttpClient _getHttpWebSQLRequest write _downloadDatabaseName : $_downloadDatabaseName list: $event");
              ioSink.add(event);
            } else {
              onDownloadDBFileResult("0", routerId);
            }
          }, onDone: () {
            ioSink?.close();
            Log.message(
                "WebSQLHttpClient _getHttpWebSQLRequest end _downloadDatabaseName : $_downloadDatabaseName");
            onDownloadDBFileResult("1", routerId);
          }, onError: () {
            ioSink?.close();
            onDownloadDBFileResult("0", routerId);
          });
          return;
        }
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
        }).onError((error, stackTrace) {
          connectFailCallback(actionParams, routerId);
        });
      }).onError((error, stackTrace) {
        connectFailCallback(actionParams, routerId);
      });
    }).onError((error, stackTrace) {
      connectFailCallback(actionParams, routerId);
    });
  }

  void connectFailCallback(String action, String routerId) {
    Log.message("WebSQLHttpClient _getHttpWebSQLRequest connect error");
    switch (action) {
      case RouterConstants.actionCreateDB:
        for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
          callback.onOpenOrCreateDB("0", routerId);
        }
        break;
      case RouterConstants.actionDeleteDB:
        for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
          callback.onDeleteDB("0", routerId);
        }
        break;
      case RouterConstants.actionListDB:
        for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
          callback.onListDBFile([], routerId);
        }
        break;
      case RouterConstants.actionExecSQL:
        for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
          callback.onExecSQLResult("", routerId);
        }
        break;
    }
  }

  void addWebRouterCallback(WebSQLRouterCallback callback) {
    _webSQLCallbackSet.add(callback);
  }

  void removeWebRouterCallback(WebSQLRouterCallback? callback) {
    _webSQLCallbackSet.remove(callback);
  }

  void clearDownloadCache(){
    _downloadDatabaseName = null;
    _downloadDBFile = null;
    _downloadDBRouterId = null;
  }

  void destroy() {
    Log.message("WebSQLHttpClient--destroy");
    clearDownloadCache();
    _connectHostInfo = null;
    _webSQLCallbackSet.clear();
    _httpClient?.close(force: true);
    _httpClient = null;
  }
}
