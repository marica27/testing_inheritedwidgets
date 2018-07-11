import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

typedef Widget DraggableScrollThumbBuilder(
    Color color, double fadingOpacity, double height,
    {String dynamicLabelText});

typedef String DynamicLabelTextBuilder(double offsetY);

class DraggableScrollbar extends StatefulWidget {
  final BoxScrollView child;
  DraggableScrollThumbBuilder scrollThumbBuilder;
  final double heightScrollThumb;
  final Color color;
  final EdgeInsetsGeometry padding;
  final Duration scrollbarFadeDuration;
  final Duration scrollbarTimeToFade;
  DynamicLabelTextBuilder dynamicLabelTextBuilder;

  DraggableScrollbar({
    Key key,
    @required this.heightScrollThumb,
    @required this.color,
    @required this.scrollThumbBuilder,
    @required this.child,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
  })  : assert(scrollThumbBuilder != null),
        super(key: key);

  DraggableScrollbar.rrect({
    Key key,
    @required this.heightScrollThumb,
    @required this.color,
    @required this.child,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
  }) : super(key: key) {
    scrollThumbBuilder = _scrollThumbBuilderRRect;
  }

  DraggableScrollbar.withArrows({
    Key key,
    @required this.heightScrollThumb,
    @required this.color,
    @required this.child,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
  }) : super(key: key) {
    scrollThumbBuilder = (Color color, double fadingOpacity, double height,
        {String dynamicLabelText}) {
      var scrollThumb =  new ClipPath(
        child: new Container(
          height: height,
          width: 20.0,
          decoration: new BoxDecoration(
              color: calculateOpacity(color, fadingOpacity),
              borderRadius: new BorderRadius.all(new Radius.circular(10.0))),
        ),
        clipper: new ArrowClipper(),
      );
      if (dynamicLabelText == null) {
        return scrollThumb;
      }
      return new Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        new Container(
            margin: new EdgeInsets.only(right: 30.0),
            child: new Material(
                elevation: 8.0,
                color: calculateOpacity(color, fadingOpacity),
                borderRadius: BorderRadius.all(new Radius.circular(15.0)),
                child: new Container(
                    constraints: new BoxConstraints.tight(new Size(70.0, 30.0)),
                    alignment: Alignment.center,
                    child: new Text(dynamicLabelText, style: new TextStyle(color: Colors.white),)))),
        scrollThumb
      ]);
    };
  }

  DraggableScrollbar.asGooglePhotos({
    Key key,
    this.heightScrollThumb = 50.0,
    this.color = Colors.white,
    @required this.child,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
  }) : super(key: key) {
    double width = heightScrollThumb * 0.6;

    scrollThumbBuilder = (Color color, double fadingOpacity, double height,
        {String dynamicLabelText}) {
      var scrollThumb = new CustomPaint(
          foregroundPainter: new ArrowCustomPainter(
              calculateOpacity(Colors.grey, fadingOpacity)),
          child: new Material(
              elevation: 8.0,
              child: new Container(
                  constraints:
                  new BoxConstraints.tight(new Size(width, height))),
              color: calculateOpacity(color, fadingOpacity),
              borderRadius: new BorderRadius.only(
                topLeft: new Radius.circular(height),
                bottomLeft: new Radius.circular(height),
                topRight: new Radius.circular(5.0),
                bottomRight: new Radius.circular(5.0),
              )));
      if (dynamicLabelText == null) {
        return scrollThumb;
      }

      return new Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        new Container(
            margin: new EdgeInsets.only(right: 10.0),
            child: new Material(
                elevation: 8.0,
                color: calculateOpacity(color, fadingOpacity),
                borderRadius: BorderRadius.all(new Radius.circular(10.0)),
                child: new Container(
                    constraints: new BoxConstraints.tight(new Size(100.0, 20.0)),
                    alignment: Alignment.center,
                    child: new Text(dynamicLabelText)))),
        scrollThumb
      ]);
    };
  }

  @override
  _DraggableScrollbarState createState() =>
      new _DraggableScrollbarState(heightScrollThumb, scrollThumbBuilder);

  //height is better 36.0
  static Widget _scrollThumbBuilderRRect(
      Color color, double fadingOpacity, double height,
      {String dynamicLabelText}) {
    return new Material(
      elevation: 8.0,
      child: new Container(
          constraints: new BoxConstraints.tight(new Size(15.0, height))),
      color: calculateOpacity(color, fadingOpacity),
      borderRadius: new BorderRadius.all(new Radius.circular(7.0)),
    );
  }

  //opacity 0.0 - invisible
  //opacity 1.0 - given color
  static Color calculateOpacity(Color color, double fadingOpacity) {
    return color.withOpacity(color.opacity * fadingOpacity);
  }
}

class _DraggableScrollbarState extends State<DraggableScrollbar>
    with TickerProviderStateMixin {
  ScrollController _controller;
  double _barOffset;
  double _viewOffset;
  bool _isDragInProcess;
  DraggableScrollThumbBuilder _scrollThumbBuilder;
  double _heightScrollThumb;
  DraggableScrollThumb _draggableScrollThumb;
  Color _color;

  AnimationController _fadeoutAnimationController;
  Animation<double> _fadeoutOpacityAnimation;
  Timer _fadeoutTimer;

  double _colorValue;

  _DraggableScrollbarState(this._heightScrollThumb, this._scrollThumbBuilder);

  @override
  void initState() {
    super.initState();
    _controller = widget.child.controller;
    _barOffset = 0.0;
    _viewOffset = 0.0;
    _isDragInProcess = false;
    _color = widget.color;

    _fadeoutAnimationController = new AnimationController(
      vsync: this,
      duration: widget.scrollbarFadeDuration,
    );
    _fadeoutOpacityAnimation = new CurvedAnimation(
        parent: _fadeoutAnimationController, curve: Curves.fastOutSlowIn);

    _draggableScrollThumb = new DraggableScrollThumb(
        color: _color,
        fadeoutOpacityAnimation: _fadeoutOpacityAnimation,
        builder: _scrollThumbBuilder,
        height: _heightScrollThumb,
        withDynamicLabel: widget.dynamicLabelTextBuilder != null);

    _fadeoutAnimationController.addListener(() {
      setState(() {
        //print("notified: ${_fadeoutAnimationController.value}");
        _colorValue = _fadeoutAnimationController.value;
      });
    });
  }

  @override
  void dispose() {
    _fadeoutAnimationController.dispose();
    _fadeoutTimer?.cancel();
    super.dispose();
  }

  double get barMaxScrollExtent => context.size.height - _heightScrollThumb;
  double get barMinScrollExtent => 0.0;
  double get viewMaxScrollExtent => _controller.position.maxScrollExtent;
  double get viewMinScrollExtent => _controller.position.minScrollExtent;

  @override
  Widget build(BuildContext context) {
    String label;
    if (widget.dynamicLabelTextBuilder != null && _isDragInProcess) {
      label = widget.dynamicLabelTextBuilder(
          _viewOffset + _barOffset + widget.heightScrollThumb / 2);
    }

    return new NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          changePosition(notification);
          return null;
        },
        child: new Stack(
          children: <Widget>[
            widget.child,
            new GestureDetector(
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: new Container(
                    alignment: Alignment.topRight,
                    margin: new EdgeInsets.only(top: _barOffset),
                    padding: widget.padding,
                    child:
                    _draggableScrollThumb.build(dynamicLabelText: label)))
          ],
        ));
  }

  //scroll bar has received notification that it's view was scrolled
  //so it should also changes his position
  //but only if it isn't dragged
  changePosition(ScrollNotification notification) {
    //print("changePosition barOffset=${_barOffset} _isDragInProcess=${_isDragInProcess}");
    if (_isDragInProcess) {
      return;
    }
    setState(() {
      if (notification is ScrollUpdateNotification) {
        double barDelta = getBarDelta(
            notification.scrollDelta, barMaxScrollExtent, viewMaxScrollExtent);
        _barOffset += barDelta;

        if (_barOffset < barMinScrollExtent) {
          _barOffset = barMinScrollExtent;
        }
        if (_barOffset > barMaxScrollExtent) {
          _barOffset = barMaxScrollExtent;
        }

        _viewOffset += notification.scrollDelta;
        if (_viewOffset < _controller.position.minScrollExtent) {
          _viewOffset = _controller.position.minScrollExtent;
        }
        if (_viewOffset > viewMaxScrollExtent) {
          _viewOffset = viewMaxScrollExtent;
        }
      }

      if (notification is ScrollUpdateNotification ||
          notification is OverscrollNotification) {
        //print("_fadeoutAnimationController ${_fadeoutAnimationController.status} ${_fadeoutAnimationController.value}");
        if (_fadeoutAnimationController.status != AnimationStatus.forward) {
          _fadeoutAnimationController.forward();
        }

        _fadeoutTimer?.cancel();
        //print("_fadeoutTimer ${_fadeoutTimer?.tick}");
        _fadeoutTimer = new Timer(widget.scrollbarTimeToFade, () {
          _fadeoutAnimationController.reverse();
          //print("reverse _fadeoutTimer ${_fadeoutTimer?.tick}");
          _fadeoutTimer = null;
        });
      }
    });
  }

  double getBarDelta(double scrollViewDelta, double barMaxScrollExtent,
      double viewMaxScrollExtent) {
    double barDelta =
        scrollViewDelta * barMaxScrollExtent / viewMaxScrollExtent;
    return barDelta;
  }

  double getScrollViewDelta(
      double barDelta, double barMaxScrollExtent, double viewMaxScrollExtent) {
    double scrollViewDelta =
        barDelta * viewMaxScrollExtent / barMaxScrollExtent;
    return scrollViewDelta;
  }

  void _onVerticalDragStart(DragStartDetails details) {
//    print("onVerticalDragStart");
    setState(() {
      _isDragInProcess = true;
//      print("onVerticalDragStart _isDragInProcess=${_isDragInProcess}");
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
//    print("onVerticalDragUpdate");
    if (_fadeoutAnimationController.status != AnimationStatus.forward) {
      _fadeoutAnimationController.forward();
    }
    setState(() {
      if (_isDragInProcess) {
        _barOffset += details.delta.dy;

        if (_barOffset < barMinScrollExtent) {
          _barOffset = barMinScrollExtent;
        }
        if (_barOffset > barMaxScrollExtent) {
          _barOffset = barMaxScrollExtent;
        }

        double viewDelta = getScrollViewDelta(
            details.delta.dy, barMaxScrollExtent, viewMaxScrollExtent);

        _viewOffset = _controller.position.pixels + viewDelta;
        if (_viewOffset < _controller.position.minScrollExtent) {
          _viewOffset = _controller.position.minScrollExtent;
        }
        if (_viewOffset > viewMaxScrollExtent) {
          _viewOffset = viewMaxScrollExtent;
        }
//        print("bar delta=${details.delta.dy} barOffset=${_barOffset} view delta=${viewDelta} viewOffset=${_viewOffset}");
        _controller.jumpTo(_viewOffset);
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
//    print("onVerticalDragEnd");
    _fadeoutTimer = new Timer(widget.scrollbarTimeToFade, () {
      _fadeoutAnimationController.reverse();
//      print("reverse _fadeoutTimer ${_fadeoutTimer?.tick}");
      _fadeoutTimer = null;
    });
    setState(() {
      _isDragInProcess = false;
      //print("onVerticalDragEnd _isDragInProcess=${_isDragInProcess}");
    });
  }
}

class ArrowCustomPainter extends CustomPainter {
  Color color;

  ArrowCustomPainter(this.color);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
//    print("size $size");
    Paint paint = new Paint();
    paint.color = this.color;

    canvas.drawPath(
        trianglePath(new Offset(15.0, 27.0), 12.0, 8.0, false), paint);
    canvas.drawPath(
        trianglePath(new Offset(15.0, 23.0), 12.0, 8.0, true), paint);
  }

  Path trianglePath(Offset o, double width, double height, bool isUp) {
    Path trianglePath = new Path();
    trianglePath.moveTo(o.dx, o.dy);
    trianglePath.lineTo(o.dx + width, o.dy);
    trianglePath.lineTo(
        o.dx + (width / 2), isUp ? o.dy - height : o.dy + height);
    trianglePath.close();
    return trianglePath;
  }
}

class DraggableScrollThumb extends ChangeNotifier {
  DraggableScrollThumb({
    @required this.color,
    @required this.fadeoutOpacityAnimation,
    @required this.builder,
    @required this.height,
    this.withDynamicLabel = false,
  })  : assert(color != null),
        assert(fadeoutOpacityAnimation != null),
        assert(builder != null),
        assert(height != null) {
    //fadeoutOpacityAnimation.addListener(opacityChanged);
  }

  ///height of the thumb
  double height;

  /// [Color] of the thumb. Mustn't be null.
  final Color color;

  /// An opacity [Animation] that dictates the opacity of the thumb.
  /// Changes in value of this [Listenable] will automatically trigger repaints.
  /// Mustn't be null.
  final Animation<double> fadeoutOpacityAnimation;

  bool withDynamicLabel;

  final DraggableScrollThumbBuilder builder;

  Widget build({String dynamicLabelText}) {
    if (fadeoutOpacityAnimation.value == 0.0) {
      //nothing to draw
      return new Container();
    }

    var widget = builder(color, fadeoutOpacityAnimation.value, height,
        dynamicLabelText: dynamicLabelText);
    return widget;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ArrowClipper extends CustomClipper<Path> {
  //16 x 36 with radius 8
  @override
  Path getClip(Size size) {
//    print("ArrowClipper $size");
    Path path = new Path();
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.lineTo(0.0, 0.0);
    path.close();

    //arrow up
    double arrowWidth = 8.0;//=arrowHeight
    double startPointX = (size.width - arrowWidth) / 2;//4.0
    double startPointY = size.height/2 - arrowWidth/2 ;//12.0
    path.moveTo(startPointX, startPointY);//4,12
    path.lineTo(startPointX + arrowWidth/2, startPointY - arrowWidth/2);//8,8
    path.lineTo(startPointX + arrowWidth, startPointY);//12,12
    path.lineTo(startPointX + arrowWidth, startPointY+1.0);//12,13
    path.lineTo(startPointX + arrowWidth/2, startPointY - arrowWidth/2 + 1.0);//8,9
    path.lineTo(startPointX, startPointY+1.0);//4,13
    path.close();

    //arrow down
    startPointY = size.height/2 + arrowWidth/2 ;//24.0;
    path.moveTo(startPointX + arrowWidth, startPointY);//12,24
    path.lineTo(startPointX + arrowWidth/2, startPointY + arrowWidth/2);//8,28
    path.lineTo(startPointX, startPointY);//4,24
    path.lineTo(startPointX, startPointY - 1.0);//4,23
    path.lineTo(startPointX + arrowWidth/2, startPointY + arrowWidth/2 - 1.0);//8,27
    path.lineTo(startPointX + arrowWidth, startPointY - 1.0);//12,23
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
