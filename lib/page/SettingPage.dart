import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/flutter_app.dart';
import 'package:web_sqlite_test/page/HomePage.dart';

class SettingPage extends StatefulWidget {
  final OnTabPageCreateListener onTabPageCreateListener;

  const SettingPage({super.key, required this.onTabPageCreateListener});

  @override
  State<StatefulWidget> createState() {
    return _SettingPageState();
  }
}

class _SettingPageState extends State<SettingPage>
    with AutomaticKeepAliveClientMixin, HomeTabTapController {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      widget.onTabPageCreateListener.call(this);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        buildSettingTitleWidget()
      ],
    );
  }

  Widget buildSettingTitleWidget() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Stack(
        children: [
          SpaceWidget.createHeightSpace(1, spaceColor: Colors.grey),
          const Center(
            child: Text(
              "设置",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1E90FF)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SpaceWidget.createHeightSpace(1, spaceColor: Colors.grey),
          )
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  onTabDoubleTap() {}

  @override
  onTabLongTap() {}

  @override
  onTabTap(bool isChangedTab) {}
}
