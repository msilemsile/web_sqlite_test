import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';
import 'package:web_sqlite_test/utils/HostHelper.dart';

typedef OnLanBroadcastCallback = Function(String result);

class LanBroadcastService {
  static const int broadcastListenPort = 9090;

  LanBroadcastService._();

  static LanBroadcastService? _broadcastService;
  final Set<OnLanBroadcastCallback> _callbackList = {};

  static LanBroadcastService getInstance() {
    _broadcastService ??= LanBroadcastService._();
    return _broadcastService!;
  }

  RawDatagramSocket? _broadcastSocket;
  Timer? _timer;
  bool _isPeriodicBroadcast = false;
  bool _isListenBroadcast = false;

  Future<LanBroadcastService> startBroadcast() async {
    String? wifiIP = await HostHelper.getWifiIP();
    if (wifiIP == null) {
      AppToast.show("获取局域网ip失败,请检查网络连接");
      return this;
    }
    Log.message("startBroadcast local wifiIP : $wifiIP");
    _broadcastSocket ??= await RawDatagramSocket.bind(
            InternetAddress.anyIPv4, broadcastListenPort)
        .catchError((error) {
      Log.message("startBroadcast RawDatagramSocket.bind error: $error");
    });
    _periodicBroadcast(wifiIP);
    return this;
  }

  void _periodicBroadcast(String localWifiIP) {
    if (_isPeriodicBroadcast) {
      return;
    }
    List<String> splitIP = localWifiIP.split(".");
    if (splitIP.isEmpty || splitIP.length != 4) {
      return;
    }
    if (splitIP[0].compareTo("0") == 0) {
      return;
    }
    String needBroadcastIP = "${splitIP[0]}.${splitIP[1]}.${splitIP[2]}.";
    _isPeriodicBroadcast = true;
    Log.message("_sendBroadcast needBroadcastIP: $needBroadcastIP");
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      Log.message("_sendBroadcast start");
      for (int i = 1; i < 255; i++) {
        if (i.toString().compareTo(splitIP[3]) != 0) {
          Uint8List uint8list = Uint8List.fromList(
              RouterConstants.buildSocketBroadcastRoute(localWifiIP).codeUnits);
          _broadcastSocket?.send(uint8list,
              InternetAddress("$needBroadcastIP$i"), broadcastListenPort);
        }
      }
      Log.message(
          "_sendBroadcast success end ip range: [$needBroadcastIP.1 - $needBroadcastIP.254]");
    });
  }

  void sendBroadcast(String wifiIP, int port, String message) {
    Log.message("LanBroadcastService sendMessage");
    var msgInts = Uint8List.fromList(message.codeUnits);
    _broadcastSocket?.send(msgInts, InternetAddress(wifiIP), port);
  }

  void listenBroadcast(OnLanBroadcastCallback? callback) {
    if (_broadcastSocket == null) {
      AppToast.show("请在设置页打开局域网互操作", AppToast.lengthLong);
      return;
    }
    if (callback != null) {
      _callbackList.add(callback);
    }
    if (_isListenBroadcast) {
      return;
    }
    _isListenBroadcast = true;
    _broadcastSocket?.listen((RawSocketEvent socketEvent) {
      Log.message("listenBroadcast socketEvent:  $socketEvent");
      if (socketEvent == RawSocketEvent.read) {
        Datagram? datagram = _broadcastSocket?.receive();
        if (datagram != null) {
          String receiveData = String.fromCharCodes(datagram.data);
          Log.message("listenBroadcast receiveData:  $receiveData");
          for (OnLanBroadcastCallback callback in _callbackList) {
            callback(receiveData);
          }
        }
      }
    });
  }

  void removeBroadcastCallback(OnLanBroadcastCallback? callback){
    _callbackList.remove(callback);
  }

  void stopBroadcast() {
    _callbackList.clear();
    _isPeriodicBroadcast = false;
    _timer?.cancel();
    _timer = null;
    _isListenBroadcast = false;
    _broadcastSocket?.close();
    _broadcastSocket = null;
    Log.message("stopBroadcast over");
  }
}
