import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/common/log/Log.dart';
import 'package:flutter_app/common/widget/AppToast.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';

import '../model/WebSQLRouter.dart';
import '../router/RouterManager.dart';
import '../utils/HostHelper.dart';

typedef OnConnectStateCallback = Function(String state);

class LanConnectService {
  static const int connectListenPort = 9494;
  static const String connectStateSuccess = "连接成功";
  static const String connectStateTimeout = "连接超时";
  static const String connectStateError = "连接失败";

  LanConnectService._();

  static LanConnectService? _lanConnectService;

  static LanConnectService getInstance() {
    _lanConnectService ??= LanConnectService._();
    return _lanConnectService!;
  }

  final Set<OnSendWebRouterMessageCallback> _sendWebRouterMsgCallback = {};
  RawSocket? _clientSocket;
  RawServerSocket? _serverSocket;
  HostInfo? _connectHostInfo;
  OnConnectStateCallback? _connectStateCallback;
  Timer? _connectTimeoutTimer;

  Future<LanConnectService> connectService(HostInfo hostInfo,
      [OnConnectStateCallback? onConnectStateCallback]) async {
    Log.message("LanConnectService connectService hostInfo : $hostInfo");
    String? wifiIP = await HostHelper.getInstance().getWifiIP();
    if (wifiIP == null) {
      AppToast.show("获取ip失败,请检查网络连接");
      return this;
    }
    if (_clientSocket != null) {
      sendMessage(RouterConstants.buildSocketUnConnectRoute(wifiIP));
      unConnectService();
    }
    _connectStateCallback = onConnectStateCallback;
    _connectTimeoutTimer = Timer(const Duration(seconds: 3), () {
      if (_connectStateCallback != null) {
        _connectStateCallback!(connectStateTimeout);
      }
      unConnectService();
    });
    _clientSocket = await RawSocket.connect(hostInfo.host, connectListenPort)
        .catchError((error) {
      if (_connectStateCallback != null) {
        _connectStateCallback!(connectStateError);
      }
      unConnectService();
      Log.message(
          "LanConnectService connectService RawSocket.connect error: $error");
    });
    _listenConnect();
    return this;
  }

  Future<LanConnectService> bindService() async {
    Log.message("LanConnectService bindService");
    String? wifiIP = await HostHelper.getInstance().getWifiIP();
    if (wifiIP == null) {
      AppToast.show("获取ip失败,请检查网络连接");
      return this;
    }
    _serverSocket =
        await RawServerSocket.bind(InternetAddress.anyIPv4, connectListenPort)
            .catchError((error) {
      Log.message(
          "LanConnectService bindService RawServerSocket.connect error: $error");
    });
    _serverSocket?.listen((rawSocket) {
      Log.message("LanConnectService bindService connect is coming");
      if (_clientSocket != null) {
        sendMessage(RouterConstants.buildSocketUnConnectRoute(wifiIP));
        unConnectService();
      }
      _clientSocket = rawSocket;
      sendMessage(RouterConstants.buildSocketConnectRoute(wifiIP, 1));
      _listenConnect();
    });
    return this;
  }

  void _listenConnect() {
    _clientSocket?.listen((socketEvent) {
      Log.message(
          "LanConnectService listenBroadcast _clientSocket socketEvent:  $socketEvent");
      if (socketEvent == RawSocketEvent.read) {
        Uint8List? uint8list = _clientSocket?.read(_clientSocket?.available());
        if (uint8list != null) {
          String dataReceive = String.fromCharCodes(uint8list);
          Log.message(
              "LanConnectService listenBroadcast _clientSocket dataReceive:  $dataReceive");
          WebSQLRouter? webSQLRouter =
              RouterManager.parseToWebSQLRouter(dataReceive);
          if (webSQLRouter != null && webSQLRouter.action != null) {
            Map<String, dynamic>? jsonData = webSQLRouter.jsonData;
            String? host;
            String? platform;
            String? shakeHands;
            if (jsonData != null) {
              host = jsonData[RouterConstants.dataHost];
              platform = jsonData[RouterConstants.dataPlatform];
              shakeHands = jsonData[RouterConstants.dataShakeHands];
            }
            if (webSQLRouter.action!.compareTo(RouterConstants.actionConnect) ==
                0) {
              if (host != null && platform != null) {
                cancelConnectTimeoutTimer();
                _connectHostInfo = HostInfo(host, platform);
                if (_connectStateCallback != null) {
                  _connectStateCallback!(connectStateSuccess);
                }
                AppToast.show("与主机:$host建立了连接");
                if (shakeHands != null && shakeHands.compareTo("1") == 0) {
                  String? wifiIP = HostHelper.getInstance().getWifiIP();
                  if (wifiIP != null) {
                    sendMessage(
                        RouterConstants.buildSocketConnectRoute(wifiIP));
                  }
                }
              }
            } else if (webSQLRouter.action!
                    .compareTo(RouterConstants.actionUnConnect) ==
                0) {
              AppToast.show("与主机:$host断开");
            } else {
              for (OnSendWebRouterMessageCallback webRouterMsgCallback
                  in _sendWebRouterMsgCallback) {
                webRouterMsgCallback.onMessageCallback(webSQLRouter);
              }
            }
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
    return _connectHostInfo != null;
  }

  HostInfo? getCurrentConnectHostInfo() {
    return _connectHostInfo;
  }

  void addSendMessageCallback(OnSendWebRouterMessageCallback callback) {
    _sendWebRouterMsgCallback.add(callback);
  }

  void removeSendMessageCallback(OnSendWebRouterMessageCallback? callback) {
    _sendWebRouterMsgCallback.remove(callback);
  }

  void unbindService() {
    _serverSocket?.close();
    _serverSocket = null;
  }

  void cancelConnectTimeoutTimer() {
    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = null;
  }

  void unConnectService() {
    cancelConnectTimeoutTimer();
    _connectHostInfo = null;
    _connectStateCallback = null;
    _sendWebRouterMsgCallback.clear();
    _clientSocket?.close();
    _clientSocket = null;
    Log.message("LanConnectService unConnectService over");
  }

  void destroy() {
    unbindService();
    unConnectService();
  }
}

mixin OnSendWebRouterMessageCallback {
  onMessageCallback(WebSQLRouter webSQLRouter);
}
