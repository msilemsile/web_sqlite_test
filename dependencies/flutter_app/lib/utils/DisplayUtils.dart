import 'package:flutter/cupertino.dart';

///显示工具类

class DisplayUtils {

  static double getStatusBarHeight(BuildContext context){
    return MediaQuery.of(context).padding.top;
  }


  static double getViewInsetBottomHeight(BuildContext context){
    return MediaQuery.of(context).viewInsets.bottom;
  }

}
