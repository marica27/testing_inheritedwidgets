import 'package:flutter/material.dart';
import 'dart:async';

import 'package:after_layout/after_layout.dart';


class UnboundedScrollPosition extends ScrollPositionWithSingleContext {
  UnboundedScrollPosition({
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
    double initialPixels,
  }) : super(
            physics: physics,
            context: context,
            initialPixels: initialPixels,
            oldPosition: oldPosition);

  @override
  double get minScrollExtent => double.negativeInfinity;
}

class UnboundedScrollController extends ScrollController {
  UnboundedScrollController({
    double initialScrollOffset: 0.0,
    keepScrollOffset: true,
    debugLabel,
  }) : super(
            initialScrollOffset: initialScrollOffset,
            keepScrollOffset: keepScrollOffset,
            debugLabel: debugLabel);

  @override
  UnboundedScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    print("UnboundedScrollPosition: ${context} ${oldPosition}");
    return new UnboundedScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      initialPixels: initialScrollOffset,
    );
  }
}

class DividedListView extends StatefulWidget {
  factory DividedListView({
    Key key,
    List<Widget> children,
    int startIndex,
  }) {
    return new DividedListView.builder(
      startIndex: startIndex,
      itemCount: children.length,
      itemBuilder: (BuildContext context, int index) {
        return children[index % children.length];
      },
    );
  }

  DividedListView.builder(
      {Key key, this.itemBuilder, this.itemCount, this.startIndex = 0})
      : assert(startIndex != null),
        super(key: key);

  final int itemCount;
  final int startIndex;
  final IndexedWidgetBuilder itemBuilder;

  DividedListViewState createState() => new DividedListViewState();
}

class DividedListViewState extends State<DividedListView> {
    //with AfterLayoutMixin<DividedListView> {
  UnboundedScrollController _controller;
  UnboundedScrollController _negativeController;

  @override
  void initState() {
    print("initState");
    super.initState();
    _controller?.dispose();
    _negativeController?.dispose();
    _controller = new UnboundedScrollController(keepScrollOffset: false);
    _negativeController = new UnboundedScrollController();

    //_controller.addListener(jumpNegativeController);

    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      print("addPersistentFrameCallback");
      jumpNegativeController();
    });
  }

  void jumpNegativeController() {
    var extentInside = -_negativeController.position.extentInside;
    print(
        "negC jump to ${extentInside} - ${_controller.position.pixels} = ${-_negativeController.position.extentInside -
        _controller.position.pixels}");
    _negativeController.jumpTo(extentInside - _controller.position.pixels);
  }

  @override
  void dispose() {
    print("dispose");
    // _controller.removeListener(jumpNegativeController);
    super.dispose();
  }

  @override
  void didUpdateWidget(DividedListView oldWidget) {
    print("didUpdateWidget ${oldWidget}");
    _controller?.dispose();
    _negativeController?.dispose();
    _controller = new UnboundedScrollController(keepScrollOffset: false);
    _negativeController = new UnboundedScrollController();

    super.didUpdateWidget(oldWidget);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    print("afterFirstLayout");
    _negativeController.jumpTo(-_negativeController.position.extentInside -
        _controller.position.pixels);
  }

  @override
  Widget build(BuildContext context) {
    print("DividedListViewState index=${widget.startIndex}");
    return new Stack(
      children: <Widget>[
        new CustomScrollView(
          key: new GlobalObjectKey("neg${widget.startIndex}"),
          physics: new AlwaysScrollableScrollPhysics(),
          controller: _negativeController,
          reverse: true,
          slivers: <Widget>[
            new SliverList(
              delegate: new SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                var item = new Container(
                    key: new GlobalObjectKey(widget.startIndex - index - 1),
                    decoration:
                        BoxDecoration(border: Border.all(color: Colors.black)),
                    child: widget.itemBuilder(
                      context,
                      widget.startIndex - index - 1,
                    ));
                print(
                    "CustomScrollView $index neg.offset=${_negativeController.position.pixels} widget.key=${item.key}");
                return item;
              }),
            ),
          ],
        ),
        new ListView.builder(
          key: new GlobalObjectKey("pos${widget.startIndex}"),
          controller: _controller,
          itemBuilder: (BuildContext context, int index) {
            var item = new Container(
                key: new GlobalObjectKey(widget.startIndex + index),
                child: widget.itemBuilder(context, widget.startIndex + index));
            print(
                "ListView.builder $index pos.offset=${_controller.position.pixels} widget.key=${item.key}");
            return item;
          },
        ),
      ],
    );
  }
}
