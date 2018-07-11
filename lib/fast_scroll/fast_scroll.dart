library fast_scroll;

import 'fast_scroll_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';



class FastScroll extends StatefulWidget {

  final Widget child;

  const FastScroll({Key key, this.child}) : super(key: key);

  @override
  _FastScrollState createState() => new _FastScrollState();
}

class _FastScrollState extends State<FastScroll> {


  FastScrollPainter _scrollPainter;

  TextDirection _textDirection;
  Color _themeColor;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final ThemeData theme = Theme.of(context);

    _themeColor = theme.highlightColor.withOpacity(1.0);
    _textDirection = Directionality.of(context);
    _scrollPainter = _buildMaterialScrollbarPainter();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    _scrollPainter.update(notification.metrics, notification.metrics.axisDirection);
    return false;
  }

  bool _handleIndexChanged(IndexChangedNotification notification) {
    _scrollPainter.updateIndex(notification.index);
    return false;
  }

  FastScrollPainter _buildMaterialScrollbarPainter() {
    return new FastScrollPainter(
      color: _themeColor,
      textDirection: _textDirection,
      thickness: 30.0,
    );
  }

  @override
  Widget build(BuildContext context) {

    return new NotificationListener<IndexChangedNotification>(
      onNotification: _handleIndexChanged,
      child: new NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: new RepaintBoundary(
              child: new CustomPaint(
                painter: _scrollPainter,
                child: new RepaintBoundary(
                  child: widget.child,
                ),
              )
          )
      ),
    );
  }
}

class IndexString extends StatefulWidget {

  final Widget child;
  final String name;
  const IndexString({Key key, this.child, this.name}) : super(key: key);

  @override
  _IndexStringState createState() => new _IndexStringState();
}


class _IndexStringState extends State<IndexString> {

  ScrollableState _scrollable;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if(_scrollable == null) {
      _scrollable = Scrollable.of(context);
      _scrollable.position.addListener(onScroll);
    }

  }


  void onScroll() {
    //context.ancestorRenderObjectOfType();

    var box = context.findRenderObject() as RenderBox;
    if(box.parent is RenderRepaintBoundary) {
      box = box.parent as RenderBox;
    }
    if(box.parentData is SliverLogicalParentData) {
      var data = box.parentData as SliverLogicalParentData;
      print("data.offset: ${data.layoutOffset}");
    } else {
      print("box.parentData.runtimeType: ${box.parentData.runtimeType}");
    }
  }


  @override
  void dispose() {
    _scrollable?.position?.removeListener(onScroll);
    _scrollable = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }


}



class IndexStringSingleChildLayoutDelegate extends SingleChildLayoutDelegate {

  final BuildContext context;
  final String name;

  IndexStringSingleChildLayoutDelegate(this.context, this.name);


  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var box = context.findRenderObject() as RenderBox;
    print("box.semanticBounds.top: ${box.semanticBounds.top}");
    //   new IndexChangedNotification(name).dispatch(context);
    return Offset.zero;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints;

  @override
  Size getSize(BoxConstraints constraints) => constraints.smallest;

  @override
  bool shouldRelayout(SingleChildLayoutDelegate oldDelegate) => true;

}

class IndexChangedNotification extends Notification {

  final String index;

  IndexChangedNotification(this.index);
}
