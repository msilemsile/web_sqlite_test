import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';
import 'package:web_sqlite_test/utils/HostHelper.dart';

typedef OnLanBroadcastCallback = Function(String result);

class LanBroadcastService {
  static String multicastAddress = "239.123.123.123";
  static int connectListenPort = 9191;

  LanBroadcastService._();

  static LanBroadcastService? _broadcastService;
  final Set<OnLanBroadcastCallback> _callbackList = {};

  static LanBroadcastService getInstance() {
    _broadcastService ??= LanBroadcastService._();
    return _broadcastService!;
  }

  RawDatagramSocket? _multiCastSocket;
  bool _stopPeriodicBroadcast = false;
  bool _isListenBroadcast = false;

  Future<LanBroadcastService> startBroadcast() async {
    String? wifiIP = await HostHelper.getInstance().getWifiIP();
    if (wifiIP == null) {
      AppToast.show("获取ip失败,请检查网络连接");
      return this;
    }
    Log.message("LanBroadcastService startBroadcast local wifiIP : $wifiIP");
    _multiCastSocket ??= await RawDatagramSocket.bind(
            InternetAddress.anyIPv4, connectListenPort,
            reusePort: !Platform.isAndroid)
        .catchError((error) {
      Log.message(
          "LanBroadcastService startBroadcast _multiCastSocket bind error: $error");
    });
    _multiCastSocket?.joinMulticast(InternetAddress(multicastAddress));
    _isListenBroadcast = false;
    listenBroadcast(null);
    _stopPeriodicBroadcast = false;
    _periodicBroadcast(wifiIP);
    return this;
  }

  void _periodicBroadcast(String localWifiIP) async {
    if (_stopPeriodicBroadcast) {
      // Log.message("LanBroadcastService _stopPeriodicBroadcast");
      return;
    }
    // Log.message("LanBroadcastService _periodicBroadcast start");
    await sendBroadcast(multicastAddress, connectListenPort,
        RouterConstants.buildSocketBroadcastRoute(localWifiIP));
    // Log.message("LanBroadcastService _periodicBroadcast end");
    Timer(const Duration(seconds: 2), () {
      _periodicBroadcast(localWifiIP);
    });
    // Log.message("LanBroadcastService _periodicBroadcast delay 2s");
  }

  Future<void> sendBroadcast(String wifiIP, int port, String message) async {
    // Log.message("LanBroadcastService sendMessage : $message");
    var msgInts = Uint8List.fromList(message.codeUnits);
    RawDatagramSocket sendSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, 0,
        reusePort: !Platform.isAndroid);
    sendSocket.send(msgInts, InternetAddress(wifiIP), port);
    sendSocket.close();
  }

  bool isListeningBroadcast() {
    return _multiCastSocket != null;
  }

  void listenBroadcast(OnLanBroadcastCallback? callback) async {
    if (_multiCastSocket == null) {
      AppToast.show("请在设置页打开局域网数据互操作");
      return;
    }
    if (callback != null) {
      _callbackList.add(callback);
    }
    if (_isListenBroadcast) {
      return;
    }
    _isListenBroadcast = true;
    _multiCastSocket?.listen((RawSocketEvent socketEvent) {
      // Log.message(
      //     "LanBroadcastService listenBroadcast socketEvent:  $socketEvent");
      Datagram? datagram = _multiCastSocket?.receive();
      if (datagram != null) {
        String receiveData = String.fromCharCodes(datagram.data);
        // Log.message(
        //     "LanBroadcastService listenBroadcast receiveData:  $receiveData");
        for (OnLanBroadcastCallback callback in _callbackList) {
          callback(receiveData);
        }
      }
    });
  }

  void removeBroadcastCallback(OnLanBroadcastCallback? callback) {
    _callbackList.remove(callback);
  }

  void stopBroadcast() {
    _callbackList.clear();
    _stopPeriodicBroadcast = true;
    _isListenBroadcast = false;
    _multiCastSocket?.leaveMulticast(InternetAddress(multicastAddress));
    _multiCastSocket?.close();
    _multiCastSocket = null;
    Log.message("LanBroadcastService stopBroadcast over");
  }
}
