import 'package:flutter/foundation.dart';
import 'package:flutter_app/common/constant/AppConstant.dart';

///log日志
class Log {
  static void message(Object object, {String? tag, bool releasePrint = false}) {
    if (releasePrint) {
      print("${tag ?? AppConstant.appTag}: $object");
    } else if (kDebugMode) {
      print("${tag ?? AppConstant.appTag}: $object");
    }
  }
}
