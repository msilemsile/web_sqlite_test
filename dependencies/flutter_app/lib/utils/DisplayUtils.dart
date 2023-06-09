import 'package:flutter/cupertino.dart';

///显示工具类

class DisplayUtils {

  static double getStatusBarHeight(BuildContext context){
    return MediaQuery.of(context).padding.top;
  }

}
