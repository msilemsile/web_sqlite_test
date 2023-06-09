import 'dart:io';

import '../service/LanConnectService.dart';
import 'WebSQLRouter.dart';

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

  static String buildSocketBroadcastRoute(String wifiIP) {
    String webSQLRoute =
    WebSQLRouter.buildWebSQLRoute(RouterConstants.actionBroadcast, {
      "wifiIP": wifiIP,
      "port": LanConnectService.connectListenPort.toString(),
      "platform": Platform.operatingSystem
    });
    return webSQLRoute;
  }

  static String buildSocketConnectRoute(String wifiIP) {
    String webSQLRoute =
        WebSQLRouter.buildWebSQLRoute(RouterConstants.actionConnect, {
      "wifiIP": wifiIP,
      "port": LanConnectService.connectListenPort.toString(),
      "platform": Platform.operatingSystem
    });
    return webSQLRoute;
  }

  static String buildSocketUnConnectRoute(String wifiIP) {
    String webSQLRoute =
    WebSQLRouter.buildWebSQLRoute(RouterConstants.actionUnConnect, {
      "wifiIP": wifiIP,
      "port": LanConnectService.connectListenPort.toString(),
      "platform": Platform.operatingSystem
    });
    return webSQLRoute;
  }

  static String buildListDBRoute() {
    String webSQLRoute =
        WebSQLRouter.buildWebSQLRoute(RouterConstants.actionListDB);
    return webSQLRoute;
  }
}
