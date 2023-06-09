import 'package:flutter/widgets.dart';

class AppManager {
  AppManager._();

  static AppManager? _appManager;

  static AppManager getInstance() {
    _appManager ??= AppManager._();
    return _appManager!;
  }

  final GlobalKey<NavigatorState> _globalNaviStateKey = GlobalKey();

  GlobalKey<NavigatorState> globalNaviStateKey() {
    return _globalNaviStateKey;
  }

  BuildContext? getContext() {
    return _globalNaviStateKey.currentState?.overlay?.context;
  }


  OverlayState? getOverlay() {
    return _globalNaviStateKey.currentState?.overlay;
  }
}
