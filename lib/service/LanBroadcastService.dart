import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';
import 'package:web_sqlite_test/utils/HostHelper.dart';

typedef OnLanBroadcastCallback = Function(String result);

class LanBroadcastService {
  static String multicastAddress = "239.123.123.123";
  static const int broadcastListenPort = 9090;

  LanBroadcastService._();

  static LanBroadcastService? _broadcastService;
  final Set<OnLanBroadcastCallback> _callbackList = {};

  static LanBroadcastService getInstance() {
    _broadcastService ??= LanBroadcastService._();
    return _broadcastService!;
  }

  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _sendSocket;
  bool _stopPeriodicBroadcast = false;
  bool _isListenBroadcast = false;

  Future<LanBroadcastService> startBroadcast() async {
    String? wifiIP = await HostHelper.getWifiIP();
    if (wifiIP == null) {
      AppToast.show("获取局域网ip失败,请检查网络连接");
      return this;
    }
    Log.message("LanBroadcastService startBroadcast local wifiIP : $wifiIP");
    _broadcastSocket ??=
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, broadcastListenPort)
            .catchError((error) {
      Log.message(
          "LanBroadcastService startBroadcast RawDatagramSocket.bind error: $error");
    });
    _broadcastSocket?.joinMulticast(InternetAddress(multicastAddress));
    _stopPeriodicBroadcast = false;
    _periodicBroadcast(wifiIP);
    return this;
  }

  void _periodicBroadcast(String localWifiIP) async {
    if (_stopPeriodicBroadcast) {
      Log.message("LanBroadcastService _stopPeriodicBroadcast");
      return;
    }
    Log.message("LanBroadcastService _periodicBroadcast start");
    await sendBroadcast(multicastAddress, broadcastListenPort, RouterConstants.buildSocketBroadcastRoute(localWifiIP));
    Log.message("LanBroadcastService _periodicBroadcast end");
    Timer(const Duration(seconds: 2), () {
      _periodicBroadcast(localWifiIP);
    });
    Log.message("LanBroadcastService _periodicBroadcast delay 2s");
  }

  Future<void> sendBroadcast(String wifiIP, int port, String message) async {
    Log.message("LanBroadcastService sendMessage : $message");
    var msgInts = Uint8List.fromList(message.codeUnits);
    _sendSocket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _sendSocket?.send(msgInts, InternetAddress(wifiIP), port);
  }

  void listenBroadcast(OnLanBroadcastCallback? callback) async {
    if (_broadcastSocket == null) {
      await startBroadcast();
    }
    if (callback != null) {
      _callbackList.add(callback);
    }
    if (_isListenBroadcast) {
      return;
    }
    _isListenBroadcast = true;
    _broadcastSocket?.listen((RawSocketEvent socketEvent) {
      Log.message(
          "LanBroadcastService listenBroadcast socketEvent:  $socketEvent");
      if (socketEvent == RawSocketEvent.read) {
        Datagram? datagram = _broadcastSocket?.receive();
        if (datagram != null) {
          String receiveData = String.fromCharCodes(datagram.data);
          Log.message(
              "LanBroadcastService listenBroadcast receiveData:  $receiveData");
          for (OnLanBroadcastCallback callback in _callbackList) {
            callback(receiveData);
          }
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
    _broadcastSocket?.close();
    _broadcastSocket = null;
    _sendSocket?.close();
    _sendSocket = null;
    Log.message("LanBroadcastService stopBroadcast over");
  }
}
