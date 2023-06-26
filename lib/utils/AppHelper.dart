import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/service/WebSQLHttpServer.dart';
import 'package:web_sqlite_test/utils/HostHelper.dart';

import '../service/LanBroadcastService.dart';
import '../service/LanConnectService.dart';
import '../service/WebSQLHttpClient.dart';

abstract class AppHelper {
  static void releaseResource() {
    HostHelper.getInstance().releaseLocalHostInfo();
    DBWorkspaceManager.getInstance().release();
    LanConnectService.getInstance().destroy();
    LanBroadcastService.getInstance().stopBroadcast();
    WebSQLHttpServer.getInstance().destroy();
    WebSQLHttpClient.getInstance().destroy();
  }
}
