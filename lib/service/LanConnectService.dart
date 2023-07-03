import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/common/log/Log.dart';
import 'package:flutter_app/common/widget/AppToast.dart';
import 'package:web_sqlite_test/database/DBDirConst.dart';
import 'package:web_sqlite_test/database/DBFileHelper.dart';
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
  String? _downloadDatabaseName;
  String? _downloadDBRouterId;
  File? _downloadDBFile;
  IOSink? _downloadDBFileIOSink;
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
        if (_downloadDBFile != null) {
          int startFileLength = _downloadDatabaseName!.length + "start".length;
          int endFileLength = _downloadDatabaseName!.length + "end".length;
          int? availableLength = _clientSocket?.available();
          if (availableLength != null) {
            Log.message(
                "LanConnectService _downloadDatabaseName availableLength: $availableLength");
            if (availableLength == startFileLength) {
              String startFileTag = "${_downloadDatabaseName!}start";
              Uint8List? uint8list = _clientSocket?.read(availableLength);
              if (uint8list != null) {
                String dataReceive = String.fromCharCodes(uint8list);
                if (dataReceive.compareTo(startFileTag) == 0) {
                  _downloadDBFileIOSink = _downloadDBFile?.openWrite();
                  Log.message(
                      "LanConnectService start _downloadDatabaseName $_downloadDatabaseName");
                  return;
                }
              }
            }
            if (availableLength == endFileLength) {
              String endFileTag = "${_downloadDatabaseName!}end";
              Uint8List? uint8list = _clientSocket?.read(availableLength);
              if (uint8list != null) {
                String dataReceive = String.fromCharCodes(uint8list);
                if (dataReceive.compareTo(endFileTag) == 0) {
                  onDownloadDBFileResult("1", _downloadDBRouterId ?? "0");
                  Log.message(
                      "LanConnectService end _downloadDatabaseName $_downloadDatabaseName");
                  return;
                }
              }
            }
            Uint8List? uint8list = _clientSocket?.read(availableLength);
            if (uint8list != null) {
              _downloadDBFileIOSink?.add(uint8list.toList());
              Log.message(
                  "LanConnectService _downloadDatabaseName write file $_downloadDatabaseName");
            }
          }
          return;
        }
        int? availableLength = _clientSocket?.available();
        Uint8List? uint8list = _clientSocket?.read(availableLength);
        if (uint8list != null) {
          String dataReceive = String.fromCharCodes(uint8list);
          Log.message(
              "LanConnectService listenBroadcast _clientSocket dataReceive:  $dataReceive");
          WebSQLRouter? webSQLRouter =
              RouterManager.parseToWebSQLRouter(dataReceive);
          if (webSQLRouter != null && webSQLRouter.action != null) {
            Map<String, dynamic>? jsonData = webSQLRouter.jsonData;
            String? routerId = webSQLRouter.routerId;
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
            } else if (webSQLRouter.action!.compareTo(RouterConstants.actionDeleteDB) ==
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
            } else if (webSQLRouter.action!.compareTo(RouterConstants.actionDownloadDB) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                if (databaseName != null) {
                  DBFileHelper.openDBRandomAccessFile(
                          databaseName, DBDirConst.local)
                      .then((dbFile) async {
                    String startFileTag = "${databaseName}start";
                    String endFileTag = "${databaseName}end";
                    if (dbFile != null) {
                      _clientSocket
                          ?.write(Uint8List.fromList(startFileTag.codeUnits));
                      Log.message(
                          "LanConnectService start write _downloadDatabaseName $databaseName");
                      List<int> byteBuffer = List.filled(1024, 0);
                      int currentPosition = 0;
                      while (true) {
                        await dbFile.setPosition(currentPosition);
                        int readIntoLength = await dbFile.readInto(byteBuffer);
                        Log.message(
                            "LanConnectService write _downloadDatabaseName $databaseName readIntoLength: $readIntoLength");
                        if (readIntoLength < 1024) {
                          if (readIntoLength > 0) {
                            _clientSocket?.write(Uint8List.fromList(
                                byteBuffer.sublist(0, readIntoLength)));
                          }
                          break;
                        }
                        _clientSocket?.write(Uint8List.fromList(byteBuffer));
                        currentPosition += readIntoLength;
                      }
                      await dbFile.close();
                      _clientSocket
                          ?.write(Uint8List.fromList(endFileTag.codeUnits));
                      Log.message(
                          "LanConnectService end write _downloadDatabaseName $databaseName");
                    } else {
                      sendMessage(RouterConstants.buildDownloadDBResultRoute(
                          databaseName, "0", routerId));
                    }
                  });
                }
              }
            } else if (webSQLRouter.action!
                    .compareTo(RouterConstants.actionDownloadDBResult) ==
                0) {
              if (jsonData != null) {
                String? databaseName = jsonData[RouterConstants.dataDBName];
                String? result = jsonData[RouterConstants.dataResult];
                if (databaseName != null) {
                  routerId ??= "0";
                  result ??= "0";
                  onDownloadDBFileResult(result, routerId);
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

  Future<void> setDownloadDBFileInfo(
      String databaseName, String downloadRouterId) async {
    _downloadDatabaseName = databaseName;
    _downloadDBRouterId = downloadRouterId;
    _downloadDBFile = await DBFileHelper.createDBTempFile(databaseName);
  }

  Future<void> onDownloadDBFileResult(String result, String routerId) async {
    Log.message(
        "LanConnectService onDownloadDBFileResult result: $result routerId: $routerId");
    if (_downloadDatabaseName != null) {
      await _downloadDBFileIOSink?.close();
      _downloadDBFileIOSink = null;
      _downloadDBFile = null;
      await DBFileHelper.renameDBTempFile(_downloadDatabaseName!);
      for (WebSQLRouterCallback callback in _webSQLCallbackSet) {
        callback.onDownLoadDBResult(_downloadDatabaseName!, result, routerId);
      }
    }
    clearDownloadCache();
  }

  bool isDownloadDBFile() {
    return _downloadDatabaseName != null;
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

  void clearDownloadCache() {
    _downloadDatabaseName = null;
    _downloadDBFileIOSink?.close();
    _downloadDBFileIOSink = null;
    _downloadDBFile = null;
    _downloadDBRouterId = null;
  }

  void unConnectService() {
    clearDownloadCache();
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
