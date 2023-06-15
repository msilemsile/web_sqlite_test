import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/common/log/Log.dart';
import 'package:flutter_app/common/widget/AppToast.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/service/LanBroadcastService.dart';

typedef OnLanConnectCallback = Function(String result);

class LanConnectService {
  static const int connectListenPort = 9292;

  LanConnectService._();

  static LanConnectService? _lanConnectService;

  static LanConnectService getInstance() {
    _lanConnectService ??= LanConnectService._();
    return _lanConnectService!;
  }

  final Set<OnLanBroadcastCallback> _callbackList = {};
  RawSocket? _clientSocket;
  RawServerSocket? _serverSocket;

  Future<LanConnectService> connectService(HostInfo hostInfo) async {
    Log.message("LanConnectService connectService hostInfo : $hostInfo");
    if (_clientSocket != null) {
      sendMessage("unConnect");
      unConnectService();
    }
    _clientSocket = await RawSocket.connect(hostInfo.host, connectListenPort)
        .catchError((error) {
      unConnectService();
      Log.message(
          "LanConnectService connectService RawSocket.connect error: $error");
    });
    _listenConnect(null);
    return this;
  }

  Future<LanConnectService> bindService() async {
    Log.message("LanConnectService bindService");
    _serverSocket =
        await RawServerSocket.bind(InternetAddress.anyIPv4, connectListenPort)
            .catchError((error) {
      Log.message(
          "LanConnectService bindService RawServerSocket.connect error: $error");
    });
    _serverSocket?.listen((rawSocket) {
      Log.message("LanConnectService bindService connect is coming");
      AppToast.show("主机:${rawSocket.address.host}来连接了");
      _clientSocket = rawSocket;
      sendMessage("connect");
      _listenConnect(null);
    });
    return this;
  }

  void _listenConnect(OnLanBroadcastCallback? callback) {
    if (callback != null) {
      _callbackList.add(callback);
    }
    _clientSocket?.listen((socketEvent) {
      Log.message(
          "LanConnectService listenBroadcast _clientSocket socketEvent:  $socketEvent");
      if (socketEvent == RawSocketEvent.read) {
        Uint8List? uint8list = _clientSocket?.read(_clientSocket?.available());
        if (uint8list != null) {
          String dataReceive = String.fromCharCodes(uint8list);
          Log.message(
              "LanConnectService listenBroadcast _clientSocket dataReceive:  $dataReceive");
          for (OnLanBroadcastCallback callback in _callbackList) {
            callback(dataReceive);
          }
        }
      }
    });
  }

  void sendMessage(String message) {
    Log.message("LanConnectService LanConnectService sendMessage: $message");
    var msgInts = Uint8List.fromList(message.codeUnits);
    _clientSocket?.write(msgInts, 0, msgInts.length);
  }

  bool isConnectedService() {
    return _clientSocket != null;
  }

  void addConnectCallback(OnLanConnectCallback callback) {
    _callbackList.add(callback);
  }

  void removeConnectCallback(OnLanConnectCallback? callback) {
    _callbackList.remove(callback);
  }

  void unbindService() {
    _serverSocket?.close();
    _serverSocket = null;
  }

  void unConnectService() {
    _callbackList.clear();
    _clientSocket?.close();
    _clientSocket = null;
    Log.message("LanConnectService unConnectService over");
  }

  void destroy() {
    unbindService();
    unConnectService();
  }
}
