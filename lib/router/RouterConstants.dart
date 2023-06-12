import 'dart:io';

import 'package:flutter_app/common/log/Log.dart';
import 'package:web_sqlite_test/router/RouterManager.dart';

import '../service/LanConnectService.dart';

abstract class RouterConstants {
  ///base
  static const String constScheme = "websql";
  static const String constHost = "host";
  static const String constParamAction = "action";
  static const String constParamData = "data";
  static const String constParamRouterId = "routerId";

  ///param action
  static const String actionExecSQL = "execSQL";
  static const String actionListDB = "listDB";
  static const String actionConnect = "connect";
  static const String actionUnConnect = "unConnect";
  static const String actionBroadcast = "broadcast";
  static const String actionExecSQLResult = "execSQLResult";

  ///param data
  static const String dataHost = "host";
  static const String dataPort = "port";
  static const String dataPlatform = "platform";
  static const String dataResult = "result";

  static String buildSocketBroadcastRoute(String wifiIP) {
    String webSQLRoute =
        RouterManager.buildWebSQLRoute(RouterConstants.actionBroadcast, {
      dataHost: wifiIP,
      dataPort: LanConnectService.connectListenPort.toString(),
      dataPlatform: Platform.operatingSystem
    });
    return webSQLRoute;
  }

  static String buildSocketConnectRoute(String wifiIP) {
    String webSQLRoute =
        RouterManager.buildWebSQLRoute(RouterConstants.actionConnect, {
      dataHost: wifiIP,
      dataPort: LanConnectService.connectListenPort.toString(),
      dataPlatform: Platform.operatingSystem
    });
    return webSQLRoute;
  }

  static String buildListDBRoute() {
    String webSQLRoute =
        RouterManager.buildWebSQLRoute(RouterConstants.actionListDB);
    return webSQLRoute;
  }

  static String buildExecSQLResultRoute(String result) {
    var webSQLRoute = RouterManager.buildWebSQLRoute(
      RouterConstants.actionExecSQLResult, {dataResult: result});
    return webSQLRoute;
  }
}
