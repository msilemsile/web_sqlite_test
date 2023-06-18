import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/utils/HostHelper.dart';

import '../service/LanBroadcastService.dart';
import '../service/LanConnectService.dart';

abstract class AppHelper {

  static void releaseResource() {
    LanConnectService.getInstance().destroy();
    LanBroadcastService.getInstance().stopBroadcast();
    DBWorkspaceManager.getInstance().disposeAllDatabase();
    HostHelper.getInstance().releaseLocalHostInfo();
  }
}
