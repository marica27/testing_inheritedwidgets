import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram/instagram.dart';
import 'package:async_loader/async_loader.dart';

import '../main.dart';
import '../services/auth.service.dart';
import 'grid.page.dart';
import 'post.page.dart';
import '../services/models.dart';
import 'package:date_format/date_format.dart';
import 'draggablescrollbar.dart';
import 'custom.list.view.dart';
import 'dividedlistview.dart';


class ListPage extends StatefulWidget {
  User user;
  List<Post> posts;
  int selectedPost;

  ListPage(this.user, this.posts, this.selectedPost);

  @override
  _ListPageState createState() =>
      new _ListPageState(this.user, this.posts, this.selectedPost);
}

class _ListPageState extends State<ListPage> {
  User user;
  List<Post> posts;
  int _selectedPostId;
  DateTime _selectedDate;
  bool _keepScrolling;

  ScrollController _scrollController;

  _ListPageState(this.user, this.posts, this._selectedPostId);

  @override
  void initState() {
    super.initState();

    _scrollController = new ScrollController(
        keepScrollOffset: true,
        //initialScrollOffset: 20000.0,
    );
    //_keepScrolling = true;
    /*WidgetsBinding.instance.addPostFrameCallback((_) {
      print("addPostFrameCallback ${_scrollController.positions.length}");
      print("_selectedPostId $_selectedPostId ");
      //_scrollController.jumpTo(calculateOffsetForPost(_selectedPostId));
    });*/
    /* _scrollController.addListener(() {
      if (_scrollController.position.pixels == 0) {
        print("reach 0 $_selectedPostId");
        setState(() {
          _selectedPostId--;
          if (_selectedPostId < 0) {
            _selectedPostId = 0;
          }
        });
        print("reach 0 $_selectedPostId");
      }
    });
  }*/
  }

//  void updateCaptionHeights() {
//    print("updateCaptionHeights ${posts.length}");
//    _offsetIsCalculated = true;
//
//    for (Post post in posts) {
//      GlobalKey key = new GlobalObjectKey(post.postId);
//
//      key.currentWidget
//      if (key.currentContext != null) {
//        RenderBox box = key.currentContext.findRenderObject();
//        post.captionHeight = box?.size.height;
//      } else {
//        print("cannot find ${post.postId}");
//      }
//    }
//  }

//  double calculateOffsetForPost(int index) {
//    double screenWidth = MediaQuery.of(context).size.width;
//    double offset = 0.0;
//    posts.forEach((Post post){
//      double ratio = screenWidth / post.media.first.width;
//      offset += post.media.first.height * ratio +
//          post.captionHeight +
//          PostPageState.height;
//    });
//    return offset;
//  }

  int findPostByDate(DateTime date) {
    for (int i = 0; i < posts.length; i++) {
      Post post = posts[i];
      if (post.createdTime.year == date.year &&
          post.createdTime.month == date.month &&
          post.createdTime.day == date.day) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    print("build _selectedPostId $_selectedPostId");


    if (_selectedDate != null) {
      int index = findPostByDate(_selectedDate);
      print("find post index $index");
      _selectedPostId = index;
      /*_scrollController.animateTo(calculateOffsetForPost(index),
          duration: new Duration(seconds: 1), curve: Curves.easeOut);*/
    }

    /*var listView = new ListView.builder(
        controller: _scrollController,
        itemCount: posts.length,
        itemBuilder: (BuildContext context, int index) {
          Post post = posts[index + _selectedPostId];
          return new PostPage(post);
        });*/

    var listView = new DividedListView.builder(
      key: new GlobalObjectKey("list${_selectedPostId}"),
      //reverse: true,
      startIndex: _selectedPostId,
      //controller: _scrollController,
      itemBuilder: (BuildContext context, int index) {
        Post post = posts[index];
        return new PostPage(post);
      },
    );

    var offstage;
    if (_selectedPostId > 0) {
      Post post = posts[_selectedPostId - 1];
      offstage = new Offstage(
          offstage: true,
          child: new Column(children: <Widget>[
            new PostPage(post, key: new GlobalObjectKey(post.postId))
          ]));
    }
    var stack = new Stack(children: <Widget>[listView, offstage]);

    return new Scaffold(
      appBar: createAppBar(user, selectDateFromPickerListPage),
      body: new NotificationListener<OverscrollIndicatorNotification>(
        child: stack,
        onNotification: _loadmore,
      ),
    );
  }

  bool _loadmore(OverscrollIndicatorNotification notification) {
    print("OverscrollIndicatorNotification  $notification");
    if (_scrollController.position.pixels == 0) {
      print("reach 0 $_selectedPostId");
      setState(() {
        if (_selectedPostId == 0) {
          //do noting
        } else {
          /*_selectedPostId--;
          notification.disallowGlow();

          RenderBox box = new GlobalObjectKey(posts[_selectedPostId].postId)
              .currentContext
              ?.findRenderObject();
          print("box ${box}");
          if (box != null) {
            print(
                "box ${box.size} ${posts[_selectedPostId].media.first.height}");
            _scrollController.jumpTo(box.size.height);
          }*/
        }
      });
    }
    return true;
  }

  Future<Null> selectDateFromPickerListPage() async {
    print("selected date ${_selectedDate}");
    DateTime selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? new DateTime.now(),
      firstDate:
          new DateTime(2010, 10, 6), //instagram was launched: October 6, 2010
      lastDate:
          new DateTime.now(), //on instagram it's possible to choose only past
    );

    if (selected != null) {
      setState(() {
        _selectedDate = selected;
        print("selected date ${_selectedDate}");
      });
    }
  }
}

class MySliverChildBuilderDelegate extends SliverChildBuilderDelegate {
  final int startIndex;

  const MySliverChildBuilderDelegate(
    builder,
    this.startIndex, {
    childCount,
    addAutomaticKeepAlives,
    addRepaintBoundaries,
  }) : super(builder,
            childCount: childCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries);

  @override
  Widget build(BuildContext context, int index) {
    assert(builder != null);
    print("MySliverChildBuilderDelegate ${index} startIndex=${startIndex} ");
    if (index < 0 - startIndex || (childCount != null && index >= childCount))
      return null;
    print("MySliverChildBuilderDelegate build ${index}");
    Widget child = builder(context, index);
    if (child == null) return null;
    if (addRepaintBoundaries) child = new RepaintBoundary.wrap(child, index);
    if (addAutomaticKeepAlives) child = new AutomaticKeepAlive(child: child);
    return child;
  }
}
