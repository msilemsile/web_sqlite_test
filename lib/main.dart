import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/common/log/Log.dart';
import 'package:flutter_app/theme/ThemeProvider.dart';
import 'package:flutter_app/core/AppManager.dart';
import 'package:web_sqlite_test/page/HomePage.dart';

void main() {
  // debugPaintLayerBordersEnabled = true;
  FlutterError.onError = (FlutterErrorDetails errorDetail) {
    ///捕获错误
    Log.message(errorDetail);
  };
  runZoned(() {
    ///start with MaterialApp
    runApp(MaterialApp(
      navigatorKey: AppManager.getInstance().globalNaviStateKey(),
      builder: (BuildContext context, Widget? widget) {
        return ThemeProvider(
            initThemeType: ThemeProvider.typeLight, child: widget!);
      },
      home: const HomePage(),
    ));
  }, zoneSpecification: ZoneSpecification(handleUncaughtError: (Zone self,
      ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace) {
    ///捕获未知错误(异步等)
    Log.message('$error $stackTrace');
  }));
}
