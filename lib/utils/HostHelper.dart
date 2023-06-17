import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

import '../model/HostInfo.dart';

class HostHelper {
  HostHelper._();

  static HostHelper? _instance;

  static getInstance() {
    _instance ??= HostHelper._();
    return _instance!;
  }

  HostInfo? _localHostInfo;

  String? getWifiIP() {
    if (_localHostInfo != null) {
      return _localHostInfo!.host;
    }
    return null;
  }

  void releaseLocalHostInfo() {
    _localHostInfo = null;
  }

  Future<HostInfo?> getLocalHostInfo() async {
    if (_localHostInfo != null) {
      return _localHostInfo;
    }
    NetworkInfo networkInfo = NetworkInfo();
    String? wifiIP = await networkInfo.getWifiIP();
    if (wifiIP == null) {
      return null;
    }
    _localHostInfo = HostInfo(wifiIP, Platform.operatingSystem);
    _localHostInfo!.setIsLocalHost(true);
    return _localHostInfo;
  }
}
