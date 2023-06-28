import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class TriangleShapeWidget extends SingleChildRenderObjectWidget {
  final Color soldColor;
  final double width;
  final double height;

  const TriangleShapeWidget(this.soldColor, this.width, this.height,
      {super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return TriangleShapeRenderObject(soldColor, width, height);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    TriangleShapeRenderObject shapeRenderObject =
        renderObject as TriangleShapeRenderObject;
    shapeRenderObject
      ..width = width
      ..height = height
      ..soldColor = soldColor;
  }
}

class TriangleShapeRenderObject extends RenderProxyBox {
  Color soldColor;
  double width;
  double height;
  Paint? colorPaint;

  TriangleShapeRenderObject(this.soldColor, this.width, this.height);

  @override
  void paint(PaintingContext context, Offset offset) {
    Canvas canvas = context.canvas;
    Path path = Path();
    double halfWidth = width / 2;
    path
      ..moveTo(halfWidth, 0)
      ..lineTo(-halfWidth, height)
      ..lineTo(width + halfWidth, height)
      ..close();
    colorPaint ??= Paint();
    colorPaint
      ?..color = soldColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, colorPaint!);
    super.paint(context, offset);
  }
}
