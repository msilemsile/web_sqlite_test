import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/common/log/Log.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/service/LanBroadcastService.dart';

typedef OnLanConnectCallback = Function(String result);

class LanConnectService {
  static const int connectListenPort = 9191;

  LanConnectService._();

  static LanConnectService? _lanConnectService;

  static LanConnectService getInstance() {
    _lanConnectService ??= LanConnectService._();
    return _lanConnectService!;
  }

  final Set<OnLanBroadcastCallback> _callbackList = {};
  RawSocket? _connectSocket;

  Future<LanConnectService> connectService(HostInfo hostInfo) async {
    Log.message("connectService hostInfo : $hostInfo");
    _connectSocket =
        await RawSocket.connect(hostInfo.host, int.parse(hostInfo.post))
            .catchError((error) {
      Log.message("connectService RawSocket.connect error: $error");
    });
    listenConnect(null);
    return this;
  }

  void listenConnect(OnLanBroadcastCallback? callback) {
    if (callback != null) {
      _callbackList.add(callback);
    }
    _connectSocket?.listen((socketEvent) {
      Log.message("listenBroadcast socketEvent:  $socketEvent");
      if (socketEvent == RawSocketEvent.read) {
        Uint8List? uint8list =
            _connectSocket?.read(_connectSocket?.available());
        if (uint8list != null) {
          String dataReceive = String.fromCharCodes(uint8list);
          Log.message("listenBroadcast dataReceive:  $dataReceive");
          for (OnLanBroadcastCallback callback in _callbackList) {
            callback(dataReceive);
          }
        }
      }
    });
  }

  void sendMessage(String message) {
    Log.message("LanConnectService sendMessage: $message");
    var msgInts = Uint8List.fromList(message.codeUnits);
    _connectSocket?.write(msgInts, 0, msgInts.length);
  }

  bool isConnectedService() {
    return _connectSocket != null;
  }

  void unConnectService() {
    _callbackList.clear();
    _connectSocket?.close();
    _connectSocket = null;
    Log.message("LanConnectService unConnectService over");
  }
}
