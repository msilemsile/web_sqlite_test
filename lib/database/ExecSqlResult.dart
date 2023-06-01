class ExecSqlResult {
  ExecSqlResult._();

  int code = 0;
  String msg = "";
  Object data = "{}";

  static ExecSqlResult newSuccessResult(String? data) {
    ExecSqlResult execSqlResult = ExecSqlResult._();
    execSqlResult.code = 0;
    execSqlResult.msg = "success";
    execSqlResult.data = data??"{}";
    return execSqlResult;
  }

  static ExecSqlResult newErrorResult(String errorMsg) {
    ExecSqlResult execSqlResult = ExecSqlResult._();
    execSqlResult.code = -1;
    execSqlResult.msg = errorMsg;
    execSqlResult.data = "{}";
    return execSqlResult;
  }
}
