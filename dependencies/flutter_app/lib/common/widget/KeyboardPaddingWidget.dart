import 'package:flutter/cupertino.dart';
import 'package:flutter_app/flutter_app.dart';

class KeyboardPaddingWidget extends StatefulWidget {

  final Widget child;

  const KeyboardPaddingWidget({super.key, required this.child});

  @override
  State<StatefulWidget> createState() {
    return _KeyboardPaddingWidgetState();
  }
}

class _KeyboardPaddingWidgetState extends State<KeyboardPaddingWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(padding: EdgeInsets.fromLTRB(
        0, 0, 0, DisplayUtils.getViewInsetBottomHeight(context)),
      duration: const Duration(milliseconds: 90),
      child: widget.child);
  }
}
