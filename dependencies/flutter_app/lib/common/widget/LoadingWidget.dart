import 'package:flutter/material.dart';

import '../../theme/ThemeProvider.dart';
import '../../theme/res/ColorsKey.dart';

///loading组件
class LoadingWidget extends StatelessWidget {
  final double width;
  final double height;
  final double? strokeWidth;

  const LoadingWidget(
      {super.key, this.width = 50, this.height = 50, this.strokeWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? 4.0,
        valueColor: AlwaysStoppedAnimation<Color>(
            ThemeProvider.getColor(context, ColorsKey.loadingColor)),
      ),
    );
  }
}
