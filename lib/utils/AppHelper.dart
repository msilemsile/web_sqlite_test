import 'package:web_sqlite_test/utils/HostHelper.dart';

import '../service/LanBroadcastService.dart';
import '../service/LanConnectService.dart';

abstract class AppHelper {

  static void releaseResource() {
    LanBroadcastService.getInstance().stopBroadcast();
    LanConnectService.getInstance().destroy();
    HostHelper.getInstance().releaseLocalHostInfo();
  }
}
