import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

import '../model/HostInfo.dart';

abstract class HostHelper {

  static Future<String?> getWifiIP() async {
    NetworkInfo networkInfo = NetworkInfo();
    return networkInfo.getWifiIP();
  }

  static Future<HostInfo?> buildCurrentHostInfo(String port) async {
    String? wifiIP = await getWifiIP();
    if (wifiIP == null) {
      return null;
    }
    HostInfo hostInfo = HostInfo(wifiIP, port, Platform.operatingSystem);
    hostInfo.setIsLocalHost(true);
    return hostInfo;
  }
}
