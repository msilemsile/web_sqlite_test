import 'package:flutter/material.dart';

class SpaceWidget {

  static Widget createHeightSpace(double spaceHeight, {Color? spaceColor}) {
    SizedBox sizedBox = SizedBox(width: double.infinity, height: spaceHeight);
    return spaceColor != null
        ? DecoratedBox(
      decoration: BoxDecoration(color: spaceColor),
      child: sizedBox,
    )
        : sizedBox;
  }

  static Widget createWidthSpace(double spaceWidth, {Color? spaceColor}) {
    SizedBox sizedBox = SizedBox(width: spaceWidth, height: double.infinity);
    return spaceColor != null
        ? DecoratedBox(
      decoration: BoxDecoration(color: spaceColor),
      child: sizedBox,
    )
        : sizedBox;
  }

  static Widget createWidthHeightSpace(double spaceWidth, double spaceHeight,
      {Color? spaceColor}) {
    SizedBox sizedBox = SizedBox(width: spaceWidth, height: spaceHeight);
    return spaceColor != null
        ? DecoratedBox(
      decoration: BoxDecoration(color: spaceColor),
      child: sizedBox,
    )
        : sizedBox;
  }
}
