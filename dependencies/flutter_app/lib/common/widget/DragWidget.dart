import 'package:flukit/flukit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common/log/Log.dart';

class DragWidget extends StatefulWidget {
  final List<Object> children;

  const DragWidget({super.key, required this.children});

  @override
  State<StatefulWidget> createState() {
    return _DragState();
  }
}

class DragChild {
  final Widget child;
  final Function? onClickListener;
  double? right;
  double? bottom;
  double left;
  double top;
  late double _childWidth;
  late double _childHeight;

  DragChild({
    required this.child,
    this.onClickListener,
    this.bottom,
    this.right,
    this.top = 0,
    this.left = 0,
  });
}

class _DragState extends State<DragWidget> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraint) {
      return Stack(
        children: () {
          List<Widget> wrapperChildList = [];
          for (Object childWidget in widget.children) {
            if (childWidget is DragChild) {
              wrapperChildList.add(wrapperChildWidget(childWidget, constraint));
            } else if (childWidget is Widget) {
              wrapperChildList.add(childWidget);
            }
          }
          return wrapperChildList;
        }(),
      );
    });
  }

  Widget wrapperChildWidget(DragChild dragChild, BoxConstraints constraint) {
    return Positioned(
        left: dragChild.left,
        top: dragChild.top,
        child: GestureDetector(
          child: AfterLayout(
            callback: (RenderAfterLayout renderAfterLayout) {
              dragChild._childWidth = renderAfterLayout.rect.width;
              dragChild._childHeight = renderAfterLayout.rect.height;
              bool needRefresh = false;
              if (dragChild.right != null) {
                dragChild.left = constraint.maxWidth -
                    dragChild.right!.abs() -
                    dragChild._childWidth;
                needRefresh = true;
              }
              if (dragChild.bottom != null) {
                dragChild.top = constraint.maxHeight -
                    dragChild.bottom!.abs() -
                    dragChild._childHeight;
                needRefresh = true;
              }
              if (needRefresh) {
                Log.message("--RenderAfterLayout--needRefresh");
                setState(() {});
              }
            },
            child: dragChild.child,
          ),
          onPanUpdate: (DragUpdateDetails details) {
            setState(() {
              double rightEdge = constraint.maxWidth - dragChild._childWidth;
              double bottomEdge = constraint.maxHeight - dragChild._childHeight;
              dragChild.left += details.delta.dx;
              dragChild.top += details.delta.dy;
              if (dragChild.left <= 0) {
                dragChild.left = 0;
              }
              if (dragChild.left >= rightEdge) {
                dragChild.left = rightEdge;
              }
              if (dragChild.top <= 0) {
                dragChild.top = 0;
              }
              if (dragChild.top >= bottomEdge) {
                dragChild.top = bottomEdge;
              }
            });
          },
          onTap: () {
            dragChild.onClickListener?.call();
          },
        ));
  }
}
