import 'dart:io';

import 'package:flutter_app/common/log/Log.dart';
import 'package:flutter_app/common/widget/AppToast.dart';
import 'package:web_sqlite_test/database/DBDirConst.dart';
import 'package:web_sqlite_test/model/WebSQLRouter.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';
import 'package:web_sqlite_test/router/RouterManager.dart';

import '../utils/HostHelper.dart';

class WebSQLHttpServer {
  WebSQLHttpServer._();

  static WebSQLHttpServer? _instance;

  static WebSQLHttpServer getInstance() {
    _instance ??= WebSQLHttpServer._();
    return _instance!;
  }

  static const int httpServerListenPort = 9292;

  HttpServer? _httpServer;
  String? _httpServerPath;

  Future<WebSQLHttpServer> startServer() async {
    String? wifiIP = await HostHelper.getInstance().getWifiIP();
    if (wifiIP == null) {
      AppToast.show("获取ip失败,请检查网络连接");
      return this;
    }
    Log.message(
        "WebSQLHttpServer--startServer wifiIP:$wifiIP post:$httpServerListenPort");
    _httpServerPath = null;
    _httpServer = await HttpServer.bind(
        InternetAddress.anyIPv4, httpServerListenPort,
        shared: true);
    if (_httpServer != null) {
      _httpServerPath = "http://$wifiIP:$httpServerListenPort";
      Log.message(
          "WebSQLHttpServer--startServer http uri: http://$wifiIP:$httpServerListenPort");
    }
    _httpServer?.listen((httpRequest) {
      Log.message("WebSQLHttpServer--listen httpRequest$httpRequest");
      Map<String, String> parameters = httpRequest.uri.queryParameters;
      WebSQLRouter? webSQLRouter =
          RouterManager.convertWebSQLRouter(parameters);
      if (parameters.isNotEmpty && webSQLRouter != null) {
        if (webSQLRouter.action == null) {
          writeApiResponse(httpRequest);
        } else {
          RouterManager.handleRouteAction(webSQLRouter, (result, [routerId]) {
            HttpResponse httpResponse = httpRequest.response;
            httpResponse.writeln(result);
            httpResponse.close();
          }, DBDirConst.local);
        }
      } else {
        writeApiResponse(httpRequest);
      }
    });
    return this;
  }

  void writeApiResponse(HttpRequest httpRequest) {
    HttpResponse httpResponse = httpRequest.response;
    String serverPath = getHttpServerPath();
    httpResponse
        .writeln("仅支持WebSQL操作,GET请求API如下:(!!!data块为json格式数据,需要url encode编码)");
    httpResponse.writeln("1.获取数据库列表:");
    httpResponse.writeln("$serverPath?action=${RouterConstants.actionListDB}");
    httpResponse.writeln("2.创建数据库:");
    httpResponse.writeln(
        "$serverPath?action=${RouterConstants.actionCreateDB}&data={${RouterConstants.dataDBName}:数据库名称}");
    httpResponse.writeln("3.删除数据库:");
    httpResponse.writeln(
        "$serverPath?action=${RouterConstants.actionDeleteDB}&data={${RouterConstants.dataDBName}:数据库名称}");
    httpResponse.writeln("4.执行数据库命令:");
    httpResponse.writeln(
        "$serverPath?action=${RouterConstants.actionExecSQL}&data={${RouterConstants.dataDBName}:数据库名称},${RouterConstants.dataSQL}:数据库语句");
    httpResponse.close();
  }

  String getHttpServerPath() {
    if (_httpServerPath != null) {
      return _httpServerPath!;
    }
    return "https://{主机IP}:$httpServerListenPort";
  }

  void destroy() {
    Log.message("WebSQLHttpServer--destroy");
    _httpServer?.close(force: true);
    _httpServer = null;
    _httpServerPath = null;
  }
}
