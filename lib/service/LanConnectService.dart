import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/common/log/Log.dart';
import 'package:flutter_app/common/widget/AppToast.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:web_sqlite_test/database/DBWorkspaceManager.dart';
import 'package:web_sqlite_test/model/DBFileInfo.dart';
import 'package:web_sqlite_test/model/HostInfo.dart';
import 'package:web_sqlite_test/router/RouterConstants.dart';

import '../model/WebSQLRouter.dart';
import '../router/RouterManager.dart';
import '../utils/HostHelper.dart';

typedef OnConnectStateCallback = Function(String state);
typedef OnWebRouterListDBCallback = Function(List<DBFileInfo> dbFileList);
typedef OnWebRouterExeSQLCallback = Function(String reslut);

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

  RawSocket? _clientSocket;
  RawServerSocket? _serverSocket;
  HostInfo? _connectHostInfo;
  Set<OnLanServiceCallback> _serviceCallbackSet = Set<OnLanServiceCallback>();
  Timer? _connectTimeoutTimer;

  Future<LanConnectService> connectService(HostInfo hostInfo) async {
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
    _connectTimeoutTimer = Timer(const Duration(seconds: 3), () {
      for (OnLanServiceCallback serviceCallback in _serviceCallbackSet) {
        serviceCallback.onConnectState(connectStateTimeout);
      }
      unConnectService();
    });
    _clientSocket = await RawSocket.connect(hostInfo.host, connectListenPort)
        .catchError((error) {
      for (OnLanServiceCallback serviceCallback in _serviceCallbackSet) {
        serviceCallback.onConnectState(connectStateError);
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
                for (OnLanServiceCallback serviceCallback in _serviceCallbackSet) {
                  serviceCallback.onConnectState(connectStateSuccess);
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
              String? host;
              if (jsonData != null) {
                host = jsonData[RouterConstants.dataHost];
              }
              AppToast.show("与主机:$host断开");
            } else if (webSQLRouter.action!.compareTo(RouterConstants.actionListDB) ==
                0) {
              DBWorkspaceManager.getInstance()
                  .listWorkspaceDBFile()
                  .then((dbFileList) {
                sendMessage(RouterConstants.buildListDBResultRoute(dbFileList));
              });
            } else if (webSQLRouter.action!
                    .compareTo(RouterConstants.actionListDBResult) ==
                0) {
              List<DBFileInfo> dbFileList = [];
              if (jsonData != null) {
                String? dbFileListJson = jsonData[RouterConstants.dataResult];
                if (dbFileListJson != null && dbFileListJson.isNotEmpty) {
                  dbFileList = jsonDecode(dbFileListJson);
                }
              }
              for (OnLanServiceCallback serviceCallback in _serviceCallbackSet) {
                serviceCallback.onListDBFile(dbFileList);
              }
            } else if (webSQLRouter.action!.compareTo(RouterConstants.actionCreateDB) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                if (databaseName != null) {
                  Future<Database?>? openOrCreateWorkspaceDB =
                      DBWorkspaceManager.getInstance()
                          .openOrCreateWorkspaceDB(databaseName);
                  if (openOrCreateWorkspaceDB != null) {
                    openOrCreateWorkspaceDB.then((value) {
                      if (value != null) {
                        sendMessage(RouterConstants.buildCreateDBResultRoute(
                            databaseName, 1));
                      } else {
                        sendMessage(RouterConstants.buildCreateDBResultRoute(
                            databaseName, 0));
                      }
                    });
                  } else {
                    sendMessage(RouterConstants.buildCreateDBResultRoute(
                        databaseName, 0));
                  }
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
              }
            } else if (webSQLRouter.action!
                    .compareTo(RouterConstants.actionDeleteDB) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                if (databaseName != null) {
                  DBWorkspaceManager.getInstance()
                      .deleteWorkspaceDB(databaseName)
                      .then((value) {
                    sendMessage(RouterConstants.buildDeleteDBResultRoute(
                        databaseName, 1));
                  });
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
              }
            } else if (webSQLRouter.action!.compareTo(RouterConstants.actionExecSQL) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                String? dataSql = jsonData[RouterConstants.dataSQL];
                if (databaseName != null && dataSql != null) {
                  DBWorkspaceManager.getInstance()
                      .getDBCommandHelper(databaseName)
                      .execSql(dataSql, [], (result) {
                    sendMessage(RouterConstants.buildExecSQLResultRoute(
                        databaseName, result));
                  });
                }
              }
            } else if (webSQLRouter.action!
                    .compareTo(RouterConstants.actionExecSQLResult) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                String? dataResult = jsonData[RouterConstants.dataResult];
                if (databaseName != null && dataResult != null) {
                  for (OnLanServiceCallback serviceCallback in _serviceCallbackSet) {
                    serviceCallback.onExecSQLResult(dataResult);
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

  void addServiceCallback(OnLanServiceCallback serviceCallback) {
    _serviceCallbackSet.add(serviceCallback);
  }

  void removeServiceCallback(OnLanServiceCallback? serviceCallback) {
    _serviceCallbackSet.remove(serviceCallback);
  }

  void unConnectService() {
    cancelConnectTimeoutTimer();
    _connectHostInfo = null;
    _serviceCallbackSet.clear();
    _clientSocket?.close();
    _clientSocket = null;
    Log.message("LanConnectService unConnectService over");
  }

  void destroy() {
    unbindService();
    unConnectService();
  }
}

mixin OnLanServiceCallback {
  onConnectState(String connectState);

  onListDBFile(List<DBFileInfo> dbFileList);

  onExecSQLResult(String result);
}
