import '../model/DBFileInfo.dart';

mixin WebSQLRouterCallback {
  onListDBFile(List<DBFileInfo> dbFileList, [String? routerId]);

  onExecSQLResult(String result, [String? routerId]);
}
