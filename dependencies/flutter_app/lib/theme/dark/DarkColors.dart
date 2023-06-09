import 'package:flutter_app/theme/res/ColorsKey.dart';
import 'package:flutter_app/theme/res/ColorsRes.dart';

///暗色模式颜色配置
class DarkColors {
  static const Map<int, int> colors = {
    ColorsKey.textColor: ColorsRes.color_ffffff,
    ColorsKey.statusBarColor: ColorsRes.color_000000,
    ColorsKey.backgroundColor: ColorsRes.color_000000,
    ColorsKey.bgLightMode: ColorsRes.color_000000,
    ColorsKey.bgDarkMode: ColorsRes.color_ffffff,
    ColorsKey.loadingColor: ColorsRes.color_0000ff,
    ColorsKey.lineColor: ColorsRes.color_ffffff,
  };
}
