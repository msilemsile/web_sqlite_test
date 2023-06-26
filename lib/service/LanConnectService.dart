import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/common/log/Log.dart';
import 'package:flutter_app/common/widget/AppToast.dart';
import 'package:web_sqlite_test/database/DBDirConst.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/model/DBFileInfo.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';
import 'package:web_sqlite_test/router/WebSQLRouterCallback.dart';
import 'package:web_sqlite_test/service/OnLanConnectCallback.dart';

import '../model/WebSQLRouter.dart';
import '../router/RouterManager.dart';
import '../utils/HostHelper.dart';

class LanConnectService {
  static const int connectListenPort = 9494;
  static const String connectStateStart = "开始连接";
  static const String connectStateSuccess = "连接成功";
  static const String connectStateTimeout = "连接超时";
  static const String connectStateError = "连接失败";
  static const String connectStateDisconnect = "连接断开";

  LanConnectService._();

  static LanConnectService? _lanConnectService;

  static LanConnectService getInstance() {
    _lanConnectService ??= LanConnectService._();
    return _lanConnectService!;
  }

  RawSocket? _clientSocket;
  RawServerSocket? _serverSocket;
  HostInfo? _connectHostInfo;
  final Set<OnLanConnectCallback> _onLanConnectSet = {};
  final Set<WebSQLRouterCallback> _webSQLCallbackSet = {};
  Timer? _connectTimeoutTimer;

  Future<LanConnectService> connectService(HostInfo hostInfo) async {
    Log.message("LanConnectService connectService hostInfo : $hostInfo");
    String? wifiIP = await HostHelper.getInstance().getWifiIP();
    if (wifiIP == null) {
      AppToast.show("获取ip失败,请检查网络连接");
      return this;
    }
    if (_clientSocket != null) {
      unConnectService();
    }
    _connectTimeoutTimer = Timer(const Duration(seconds: 3), () {
      for (OnLanConnectCallback callback in _onLanConnectSet) {
        callback.onConnectState(connectStateTimeout);
      }
      unConnectService();
    });
    for (OnLanConnectCallback callback in _onLanConnectSet) {
      callback.onConnectState(connectStateStart);
    }
    _clientSocket = await RawSocket.connect(hostInfo.host, connectListenPort)
        .catchError((error) {
      for (OnLanConnectCallback callback in _onLanConnectSet) {
        callback.onConnectState(connectStateError);
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
      if (socketEvent == RawSocketEvent.readClosed ||
          socketEvent == RawSocketEvent.closed) {
        String socketReason =
            socketEvent == RawSocketEvent.readClosed ? "readClosed" : "closed";
        AppToast.show("与主机断开 $socketReason");
        for (OnLanConnectCallback callback in _onLanConnectSet) {
          callback.onConnectState(connectStateDisconnect);
        }
      } else if (socketEvent == RawSocketEvent.read) {
        Uint8List? uint8list = _clientSocket?.read(_clientSocket?.available());
        if (uint8list != null) {
          String dataReceive = String.fromCharCodes(uint8list);
          Log.message(
              "LanConnectService listenBroadcast _clientSocket dataReceive:  $dataReceive");
          WebSQLRouter? webSQLRouter =
              RouterManager.parseToWebSQLRouter(dataReceive);
          if (webSQLRouter != null && webSQLRouter.action != null) {
            Map<String, dynamic>? jsonData = webSQLRouter.jsonData;
            String? routerId;
            if (jsonData != null) {
              routerId = jsonData[RouterConstants.dataRouterId];
            }
            Log.message(
                "_listenConnect routerId: $routerId action: ${webSQLRouter.action}");
            if (webSQLRouter.action!.compareTo(RouterConstants.actionConnect) ==
                0) {
              String? host;
              String? platform;
              String? shakeHands;
              if (jsonData != null) {
                host = jsonData[RouterConstants.dataHost];
                platform = jsonData[RouterConstants.dataPlatform];
                shakeHands = jsonData[RouterConstants.dataShakeHands];
              }
              if (host != null && platform != null) {
                cancelConnectTimeoutTimer();
                _connectHostInfo = HostInfo(host, platform);
                for (OnLanConnectCallback callback in _onLanConnectSet) {
                  callback.onConnectState(connectStateSuccess);
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
            } else if (webSQLRouter.action!.compareTo(RouterConstants.actionListDB) ==
                0) {
              DBWorkspaceManager.getInstance().listWorkspaceDBFile(
                  (dbFileList) {
                sendMessage(RouterConstants.buildListDBResultRoute(
                    dbFileList, routerId));
              }, DBDirConst.local);
            } else if (webSQLRouter.action!
                    .compareTo(RouterConstants.actionListDBResult) ==
                0) {
              List<DBFileInfo> dbFileList = [];
              if (jsonData != null) {
                String? dbFileListJson = jsonData[RouterConstants.dataResult];
                if (dbFileListJson != null && dbFileListJson.isNotEmpty) {
                  List<dynamic> jsonList = jsonDecode(dbFileListJson);
                  for (Map<String, dynamic> object in jsonList) {
                    DBFileInfo dbFileInfo = DBFileInfo.fromJson(object);
                    dbFileList.add(dbFileInfo);
                  }
                }
              }
              for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
                callback.onListDBFile(dbFileList, routerId);
              }
            } else if (webSQLRouter.action!.compareTo(RouterConstants.actionCreateDB) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                if (databaseName != null) {
                  DBWorkspaceManager.getInstance()
                      .openOrCreateWorkspaceDB(databaseName, (result) {
                    if (result.compareTo("1") == 0) {
                      sendMessage(RouterConstants.buildCreateDBResultRoute(
                          databaseName, 1, routerId));
                    } else {
                      sendMessage(RouterConstants.buildCreateDBResultRoute(
                          databaseName, 0, routerId));
                    }
                  }, DBDirConst.local);
                }
              }
            } else if (webSQLRouter.action!
                    .compareTo(RouterConstants.actionCreateDBResult) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                String? result = jsonData[RouterConstants.dataResult];
                if (databaseName != null) {
                  if (result != null && result.compareTo("1") == 0) {
                    AppToast.show("创建$databaseName数据库成功");
                  } else {
                    AppToast.show("创建$databaseName数据库失败!");
                  }
                }
                result ??= "0";
                for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
                  callback.onOpenOrCreateDB(result, routerId);
                }
              }
            } else if (webSQLRouter.action!
                    .compareTo(RouterConstants.actionDeleteDB) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                if (databaseName != null) {
                  DBWorkspaceManager.getInstance()
                      .deleteWorkspaceDB(databaseName, (result) {
                    if (result.compareTo("1") == 0) {
                      sendMessage(RouterConstants.buildDeleteDBResultRoute(
                          databaseName, 1, routerId));
                    } else {
                      sendMessage(RouterConstants.buildDeleteDBResultRoute(
                          databaseName, 0, routerId));
                    }
                  }, DBDirConst.local);
                }
              }
            } else if (webSQLRouter.action!
                    .compareTo(RouterConstants.actionDeleteDBResult) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                String? result = jsonData[RouterConstants.dataResult];
                if (databaseName != null) {
                  if (result != null && result.compareTo("1") == 0) {
                    AppToast.show("删除$databaseName数据库成功");
                  } else {
                    AppToast.show("删除$databaseName数据库失败!");
                  }
                }
                result ??= "0";
                for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
                  callback.onDeleteDB(result, routerId);
                }
              }
            } else if (webSQLRouter.action!.compareTo(RouterConstants.actionExecSQL) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                String? dataSql = jsonData[RouterConstants.dataSQL];
                if (databaseName != null && dataSql != null) {
                  DBWorkspaceManager.getInstance()
                      .execSql(databaseName, dataSql, [], (result) {
                    sendMessage(RouterConstants.buildExecSQLResultRoute(
                        databaseName, result, routerId));
                  }, DBDirConst.local);
                }
              }
            } else if (webSQLRouter.action!
                    .compareTo(RouterConstants.actionExecSQLResult) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                String? dataResult = jsonData[RouterConstants.dataResult];
                if (databaseName != null && dataResult != null) {
                  for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
                    callback.onExecSQLResult(dataResult, routerId);
                  }
                }
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

  void unbindService() {
    _serverSocket?.close();
    _serverSocket = null;
  }

  void cancelConnectTimeoutTimer() {
    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = null;
  }

  void addLanConnectCallback(OnLanConnectCallback callback) {
    _onLanConnectSet.add(callback);
  }

  void removeLanConnectCallback(OnLanConnectCallback? callback) {
    _onLanConnectSet.remove(callback);
  }

  void addWebRouterCallback(WebSQLRouterCallback callback) {
    _webSQLCallbackSet.add(callback);
  }

  void removeWebRouterCallback(WebSQLRouterCallback? callback) {
    _webSQLCallbackSet.remove(callback);
  }

  void unConnectService() {
    cancelConnectTimeoutTimer();
    _connectHostInfo = null;
    _clientSocket?.close();
    _clientSocket = null;
    Log.message("LanConnectService unConnectService over");
  }

  void destroy() {
    unbindService();
    unConnectService();
    _onLanConnectSet.clear();
    _webSQLCallbackSet.clear();
  }
}
