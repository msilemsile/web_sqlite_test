import 'package:flutter/material.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/page/BrowserPage.dart';
import 'package:web_sqlite_test/page/DatabasePage.dart';
import 'package:web_sqlite_test/page/SettingPage.dart';
import 'package:web_sqlite_test/theme/AppColors.dart';
import 'package:web_sqlite_test/utils/AppHelper.dart';

import '../service/LanBroadcastService.dart';
import '../service/LanConnectService.dart';

class HomePage extends StatefulWidget {
  static const int tabBrowser = 0;
  static const int tabDatabase = 1;
  static const int tabSetting = 2;

  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<int> _currentTab = ValueNotifier(HomePage.tabBrowser);
  final ValueNotifier<bool> _terminalShow = ValueNotifier(false);
  final PageController _pageController = PageController();
  HomeTabTapController? _browserTabController;
  HomeTabTapController? _databaseTabController;
  HomeTabTapController? _settingTabController;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        bool? canGoBack;
        int tabIndex = _currentTab.value;
        if (tabIndex == HomePage.tabBrowser) {
          canGoBack = await _browserTabController?.canGoBack();
        } else if (tabIndex == HomePage.tabDatabase) {
          canGoBack = await _databaseTabController?.canGoBack();
        } else if (tabIndex == HomePage.tabSetting) {
          canGoBack = await _settingTabController?.canGoBack();
        }
        canGoBack??=true;
        if(canGoBack){
          AppHelper.releaseResource();
        }
        return canGoBack;
      },
      child: BasePage(
        child: DragWidget(
          children: [
            Column(
              children: [
                Expanded(
                    child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  children: [
                    BrowserPage(
                      initUrl: "home",
                      onTabPageCreateListener: (controller) {
                        _browserTabController = controller;
                      },
                    ),
                    DatabasePage(
                      onTabPageCreateListener: (controller) {
                        _databaseTabController = controller;
                      },
                    ),
                    SettingPage(onTabPageCreateListener: (controller) {
                      _settingTabController = controller;
                    })
                  ],
                )),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ValueListenableBuilder(
                      valueListenable: _currentTab,
                      builder: (_, currentTabValue, child) {
                        return Column(
                          children: [
                            SpaceWidget.createHeightSpace(1,
                                spaceColor: Colors.grey),
                            Expanded(
                                child: Row(
                              children: [
                                Expanded(
                                    child: buildTabItemWidget(
                                        HomePage.tabBrowser, currentTabValue)),
                                Expanded(
                                    child: buildTabItemWidget(
                                        HomePage.tabDatabase, currentTabValue)),
                                Expanded(
                                    child: buildTabItemWidget(
                                        HomePage.tabSetting, currentTabValue)),
                              ],
                            ))
                          ],
                        );
                      }),
                )
              ],
            ),
            DragChild(
                right: 10,
                bottom: 60,
                onClickListener: () {
                  ///todo sql命令行窗体
                },
                child: ValueListenableBuilder(
                  valueListenable: _terminalShow,
                  builder: (buildContext, isShow, child) {
                    return Visibility(
                      visible: isShow,
                      child: CircleShape(
                        solidColor: Colors.white,
                        stokeWidth: 1,
                        stokeColor: AppColors.mainColor,
                        radius: 22,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset("images/icon_terminal.png"),
                        ),
                      ),
                    );
                  },
                ))
          ],
        ),
      ),
    );
  }

  Widget buildTabItemWidget(int tabIndex, int currentTab) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        bool isChangedTab = _currentTab.value != tabIndex;
        _currentTab.value = tabIndex;
        _pageController.jumpToPage(tabIndex);
        if (tabIndex == HomePage.tabBrowser) {
          _browserTabController?.onTabTap(isChangedTab);
        } else if (tabIndex == HomePage.tabDatabase) {
          _databaseTabController?.onTabTap(isChangedTab);
        } else if (tabIndex == HomePage.tabSetting) {
          _settingTabController?.onTabTap(isChangedTab);
        }
      },
      onDoubleTap: () {
        if (_currentTab.value != tabIndex) {
          return;
        }
        if (tabIndex == HomePage.tabBrowser) {
          _browserTabController?.onTabDoubleTap();
        } else if (tabIndex == HomePage.tabDatabase) {
          _databaseTabController?.onTabDoubleTap();
        } else if (tabIndex == HomePage.tabSetting) {
          _settingTabController?.onTabDoubleTap();
        }
      },
      onLongPress: () {
        if (_currentTab.value != tabIndex) {
          return;
        }
        if (tabIndex == HomePage.tabBrowser) {
          _browserTabController?.onTabLongTap();
        } else if (tabIndex == HomePage.tabDatabase) {
          bool isTerminalShow = _terminalShow.value;
          _terminalShow.value = !isTerminalShow;
          _databaseTabController?.onTabLongTap();
        } else if (tabIndex == HomePage.tabSetting) {
          _settingTabController?.onTabLongTap();
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            buildTabItemIconAsset(tabIndex),
            width: 25,
            height: 25,
            colorBlendMode: BlendMode.srcATop,
            color: currentTab == tabIndex
                ? const Color(0xff1E90FF)
                : const Color(0xff333333),
          ),
          Text(
            buildTabItemName(tabIndex),
            style: TextStyle(
                fontSize: 10,
                color: currentTab == tabIndex
                    ? const Color(0xff1E90FF)
                    : const Color(0xff333333)),
          )
        ],
      ),
    );
  }

  String buildTabItemIconAsset(int tabIndex) {
    if (tabIndex == HomePage.tabBrowser) {
      return "images/icon_browser.png";
    } else if (tabIndex == HomePage.tabDatabase) {
      return "images/icon_database.png";
    } else {
      return "images/icon_setting.png";
    }
  }

  String buildTabItemName(int tabIndex) {
    if (tabIndex == HomePage.tabBrowser) {
      return "浏览";
    } else if (tabIndex == HomePage.tabDatabase) {
      return "数据";
    } else {
      return "设置";
    }
  }

  @override
  bool get wantKeepAlive => true;
}

typedef OnTabPageCreateListener = Function(HomeTabTapController);

mixin HomeTabTapController {
  onTabTap(bool isChangedTab);

  onTabDoubleTap();

  onTabLongTap();

  Future<bool> canGoBack();
}
