import '../model/DBFileInfo.dart';

mixin WebSQLRouterCallback {
  onDeleteDB(String result, [String? routerId]);

  onOpenOrCreateDB(String result, [String? routerId]);

  onListDBFile(List<DBFileInfo> dbFileList, [String? routerId]);

  onExecSQLResult(String result, [String? routerId]);
}
