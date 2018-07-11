import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:meta/meta.dart';


class FastScrollPainter extends ChangeNotifier implements CustomPainter {

  FastScrollPainter({
    @required this.color,
    @required this.textDirection,
    this.mainAxisMargin: 0.0,
    this.crossAxisMargin: 0.0,
    this.thickness
  })
      : assert(color != null),
        assert(textDirection != null),
        assert(thickness != null),
        assert(mainAxisMargin != null),
        assert(crossAxisMargin != null);

  ScrollMetrics _lastMetrics;
  AxisDirection _lastAxisDirection;


  /// [Color] of the thumb. Mustn't be null.
  final Color color;


  /// Distance from the scrollbar's start and end to the edge of the viewport in
  /// pixels. Mustn't be null.
  final double mainAxisMargin;

  /// Distance from the scrollbar's side to the nearest edge in pixels. Musn't
  /// be null.
  final double crossAxisMargin;

  /// Thickness of the scrollbar in its cross-axis in pixels. Mustn't be null.
  final double thickness;

  /// [TextDirection] of the [BuildContext] which dictates the side of the
  /// screen the scrollbar appears in (the trailing side). Mustn't be null.
  final TextDirection textDirection;


  String index = "e";


  Paint get _paint {
    return new Paint()
      ..color =
          color; //.withOpacity(color.opacity * fadeoutOpacityAnimation.value);
  }


  void update(ScrollMetrics metrics, AxisDirection axisDirection,) {
    _lastMetrics = metrics;
    _lastAxisDirection = axisDirection;
    notifyListeners();
  }


  void updateIndex(String index) {
    this.index = index;
    notifyListeners();
  }


  @override
  bool hitTest(Offset position) => false;


  double _getThumbX(Size size) {
    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.rtl:
        return crossAxisMargin;
      case TextDirection.ltr:
        return size.width - thickness - crossAxisMargin;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastAxisDirection == null
        || _lastMetrics == null)
      //    || fadeoutOpacityAnimation.value == 0.0)
      return;
    switch (_lastAxisDirection) {
      case AxisDirection.down:
        _paintThumb(
            _lastMetrics.extentBefore,
            _lastMetrics.extentInside,
            _lastMetrics.extentAfter,
            size.height,
            canvas,
            size,
            _paintVerticalThumb);
        break;
      case AxisDirection.up:
        _paintThumb(
            _lastMetrics.extentAfter,
            _lastMetrics.extentInside,
            _lastMetrics.extentBefore,
            size.height,
            canvas,
            size,
            _paintVerticalThumb);
        break;
      case AxisDirection.right:
        _paintThumb(
            _lastMetrics.extentBefore,
            _lastMetrics.extentInside,
            _lastMetrics.extentAfter,
            size.width,
            canvas,
            size,
            _paintVerticalThumb);
        break;
      case AxisDirection.left:
        _paintThumb(
            _lastMetrics.extentAfter,
            _lastMetrics.extentInside,
            _lastMetrics.extentBefore,
            size.width,
            canvas,
            size,
            _paintVerticalThumb);
        break;
    }
  }


  void _paintVerticalThumb(Canvas canvas, Size size, double thumbOffset) {
    final Offset thumbOrigin = new Offset(_getThumbX(size), thumbOffset);

    final Size thumbSize = new Size(thickness, 20.0);
    final Rect thumbRect = thumbOrigin & thumbSize;

    canvas.drawRect(thumbRect, _paint);

    TextSpan span = new TextSpan(
        style: new TextStyle(color: Colors.blue[800], fontSize: 24.0,
            fontFamily: 'Roboto'), text: index);
    TextPainter tp = new TextPainter(
        text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, new Offset(0.0, 0.0));
  }


  void _paintThumb(double before,
      double inside,
      double after,
      double viewport,
      Canvas canvas,
      Size size,
      void painter(Canvas canvas, Size size, double thumbOffset),) {
    var scrollLength = before + after;
    //TODO horizontal
    var translation = size.height / scrollLength;


    var pos = before * translation;

    painter(canvas, size, pos);
  }

  // TODO: implement semanticsBuilder
  @override
  SemanticsBuilderCallback get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}