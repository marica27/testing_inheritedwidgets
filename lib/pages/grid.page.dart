import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram/instagram.dart';
import 'package:async_loader/async_loader.dart';
//import 'package:date_utils/date_utils.dart';
import 'package:date_format/date_format.dart';
import 'package:after_layout/after_layout.dart';
import 'package:flutter/scheduler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/rendering.dart';
import '../main.dart';
import '../services/auth.service.dart';
import 'package:pastdate/models.dart';
import 'post.page.dart';
import 'list.page.dart';
import '../services/database.dart';
import '../services/data.syncer.dart';

import 'draggablescrollbar.dart';

final GlobalKey<GridPageState> gridPageKey = new GlobalKey<GridPageState>();

Future<List<Post>> initAndGetPost() async {
  User user = await AuthService.get().getUser();
  await InstapostDatabase.get().initialise(user.username);
  return InstapostDatabase.get().getPosts();
}

class AsyncGridPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("AsyncGridPage");
    return new FutureBuilder(
        future: Future.wait([AuthService.get().getUser(), initAndGetPost()]),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return new Scaffold(
                  appBar: new AppBar(
                    title: new Text("Loading..."),
                  ),
                  body: new Center(child: new CircularProgressIndicator()));
            default:
              if (snapshot.hasError)
                return new Text('Error: ${snapshot.error}');
              else {
                User user = snapshot.data[0];
                List<Post> posts = snapshot.data[1];
                return new GridPage(user, posts, key: gridPageKey);
              }
          }
        });
  }
}

class GridPage extends StatefulWidget {
  User user;
  List<Post> posts;
  GridPage(this.user, this.posts, {Key key}) : super(key: key);

  @override
  GridPageState createState() => new GridPageState(user, posts);
}

enum SyncState { none, process, finished }
enum ViewBy { day, month }
enum OffsetCalculation { none, process, finished }

class GridPageState extends State<GridPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _padding = 4.0;
  final _imageSqSize = 117.0;
  final _titleHeight = 30.0;
  double _imageHeight;

//  OffsetCalculation _offsetCalculation;
//  GlobalObjectKey offstageKey = new GlobalObjectKey("offstage");

  ViewBy _viewBy;
  User user;
  List<Post> posts;
  DateTime _selectedDate;
  SyncState _syncState;
  Map<String, GlobalKey> _keys;

  GlobalKey _textContainerGlobalKey = new GlobalKey();
  GlobalKey _rowGlobalKey = new GlobalKey();
//  GlobalKey _listViewGlobalKey = new GlobalKey();

  AnimationController _animationController;
  ScrollController _scrollController;

  GridPageState(this.user, this.posts);

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  //final GlobalKey<LinearProgressIndicator> _linearProgressIndicatorKey = new GlobalKey<LinearProgressIndicator>();

  @override
  void initState() {
    super.initState();
    print("grid page init");
    WidgetsBinding.instance.addObserver(this);

    //_offsetCalculation = OffsetCalculation.none;

    _viewBy = ViewBy.day;
    _keys = {};
    _syncState = SyncState.none;
    _scrollController = new ScrollController(
        debugLabel: "GridViewScroll", initialScrollOffset: 0.0);
    _animationController = new AnimationController(
        duration: new Duration(seconds: 2), vsync: this);
    _refreshIndicatorKey.currentState?.show();

  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
    //   print("grid page didUpdateWidget $_syncState");
//    if (_syncState != SyncState.process) {
//      handleDBRefresh();
//    }
  }

  @override
  dispose() {
    _animationController?.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void makeSyncInProcess() {
    print("sync is launched");
    _syncState = SyncState.process;
  }

  void makeSyncFinished() {
    print("callbackAfterFinish is called. Set _syncState = SyncState.finished");
    _syncState = SyncState.finished;
    _animationController.forward();
  }

  @override
  void didChangeMetrics() {
    print("didChangeMetrics");
//    setState(() {
//      _imageHeight = null;
//    });
  }

  double getImageHeight() {
    if (_imageHeight == null) {
      RenderBox rowRenderObject =
          _rowGlobalKey.currentContext?.findRenderObject();
      print("rowRenderObject $rowRenderObject");
      if (rowRenderObject != null) {
        print("row render object height ${rowRenderObject.size
                .height} ${rowRenderObject.size.width}");
        _imageHeight = rowRenderObject.size.height;
        return rowRenderObject.size.height;
      }
    } else {
      return _imageHeight;
    }
    return _imageSqSize + _padding;
  }

  //when come back after navigation _selectedDate is null
  @override
  Widget build(BuildContext context) {
    print(
        "GridPageState builds with _syncState=${_syncState} username=${user.username}, "
        "posts.lentgh=${posts?.length}, "
        "_viewBy=${_viewBy}, "
        "selectedDate=${_selectedDate?.toIso8601String()}");

    if (_syncState == SyncState.none) {
      DataSyncer.get().makeSync(
          callbackBefore: makeSyncInProcess,
          callbackAfterEachBatch: handleDBRefresh,
          callbackAfterFinish: makeSyncFinished);
    }

    Map<DateTime, List<Post>> dateToPosts = generateDateToPosts(posts);
    List<DateTime> dates = dateToPosts.keys.toList()
      ..sort((DateTime a, DateTime b) => b.compareTo(a));
    SnackBar snackBar;
    if (_selectedDate != null && _scrollController.hasClients) {
      int dateIndex = dates.indexOf(_selectedDate);

      if (dateIndex < 0) {
        //find the nearest date for _selectedDate

        int index = 0, diff;
        do {
          diff = dates[index].millisecondsSinceEpoch -
              _selectedDate.millisecondsSinceEpoch;
          index++;
          print("$diff");
        } while (diff > 0 && index < dates.length);

        dateIndex = index-1;
        print(
            "find the nearest date for ${_selectedDate} -  ${dates[dateIndex]}");
        snackBar = SnackBar(content: Text("There are no post at ${dateToString(_selectedDate)}."));
      }

      //found container with posts for this _selectedDate
      //calculate offset for this tittle
      int totalColumn = getTotalColumn();
      double offset = 0.0;
      DateTime date = dates[dateIndex];
      double rowSize = getImageHeight();
      print("rowSize ${rowSize}");
      for (int i = 0; i < dateIndex; i++) {
        int rows = ((dateToPosts[dates[i]].length - 1) ~/ totalColumn) + 1;
        offset += _titleHeight + rows * rowSize;
      }
      print("scroll to offset ${offset} for date ${date}");
      final post0 = dateToPosts[date][0];

      _scrollController.animateTo(offset,
          duration: new Duration(seconds: 3), curve: Curves.ease);
    }

    Widget listView = new ListView.builder(
        itemCount: dates.length,
        //key: _listViewGlobalKey,
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        itemBuilder: (BuildContext context, int index) {
//          print("build index ${index} _offsetIsCalculated=$_offsetCalculation");
//          updateCaptionHeights();

          var date = dates[index];
          String dateString = dateToString(date);

          // print("build grid for $date, ${dateToPosts[date].length}");
          Widget grid = _buildGrid(dateToPosts[date],
              key: index == 0 ? _rowGlobalKey : null);

          return new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Container(
                    //key: index == 0 ? _textContainerGlobalKey : null,
                    padding: EdgeInsets.fromLTRB(4.0, 2.0, 4.0, 2.0),
                    height: _titleHeight,
                    child: new Text(
                      dateString,
                      style: Theme.of(context).textTheme.title,
                    )),
                grid
              ]);
        });

    var widget = new RefreshIndicator(
        onRefresh: _handleRefresh,
        child: new DraggableScrollbar.asGooglePhotos(
            child: listView,
            dynamicLabelTextBuilder: (double offset) {
              int totalColumn = getTotalColumn();
              double offsetView = 0.0;
              double rowSize = getImageHeight();
              int dateIndex = -1;
              while (dateIndex < dateToPosts.length && offsetView < offset) {
                dateIndex++;
                int rows = ((dateToPosts[dates[dateIndex]].length - 1) ~/
                        totalColumn) +
                    1;
                offsetView += _titleHeight + rows * rowSize;
              }

              return "${dateToString(dates[dateIndex])}";
            }));

    var stack = new Stack(children: <Widget>[widget]);

    if (_syncState == SyncState.process) {
      print("new DissapearingProgressBar with ${posts.length}");
      stack.children.add(new DissapearingProgressBar(
          posts == null ? 0 : posts.length,
          user.counts.media,
          _animationController));
    }

    return new Scaffold(
        appBar: createAppBar(user, selectDateFromPicker, viewByDayCallback: () {
          setState(() {
            _viewBy = ViewBy.day;
          });
        }, viewByMonthCallBack: () {
          setState(() {
            _viewBy = ViewBy.month;
          });
        }),
        body: new Builder(builder: (BuildContext) {
//          if (snackBar != null) {
//            Scaffold.of(context).showSnackBar(snackBar);
//          }
          return stack;
        },),

    );



  }

  String dateToString(DateTime date) {
    String dateToString = _viewBy == ViewBy.day
        ? formatDate(date, [d, '-', M, '-', yyyy])
        : formatDate(date, [M, '-', yyyy]);
    return dateToString;
  }

  Widget _buildPicture(Post post) {
    if (post != null) {
      _keys.putIfAbsent(post.postId, () => new GlobalKey());
    }
    GlobalKey gKey = post == null ? null : _keys[post?.postId];
    //print("Global key for id=${post?.id} - ${gKey}");
    //MediaQuery.of(context).size.width
    Navigator.of(context).toString();
    int index = posts.indexOf(post);
    return new Expanded(
        child: post == null
            ? new Container(
                key: gKey,
                //color: Colors.amberAccent,
                //height: 100.0,
                //width: 100.0,
              )
            : GestureDetector(
                onTap: () => Navigator.of(context).push(new PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          new ListPage(user, posts, index),
                    )),
                child: new Container(
                    padding: EdgeInsets.only(bottom: _padding),
                    child: new Container(
                        color: Colors.green[50],
                        height: 120.0,
                        width: 120.0,
                        child: new CachedNetworkImage(
                          imageUrl: post.thumbnailUrl,
                          placeholder: new Container(
                              height: _imageSqSize,
                              width: _imageSqSize,
                              color: Colors.grey[200]),
                          errorWidget: new Icon(Icons.error),
                        )))));
  }

  List<Widget> createRowChildrenWithPadding(
      List<Widget> widgets, Padding padding) {
    var joined = List<Widget>();

    for (var i = 0; i < widgets.length; i++) {
      if (i != widgets.length - 1) {
        joined.add(widgets[i]);
        joined.add(padding);
      } else {
        joined.add(widgets[i]);
      }
    }
    return joined;
  }

  int getTotalColumn() {
    //with no scrollToPosition it's difiicult to support changing columns
    return MediaQuery.of(context).orientation == Orientation.portrait ? 3 : 4;
  }

  Widget _buildGrid(List<Post> posts, {GlobalKey key}) {
    int totalColumn = getTotalColumn();
    //print("_build grid with ${posts.length} posts in ${totalColumn} columns");

    List<Row> rows = new List();
    for (int i = 0, row = 0;
        row <= (posts.length - 1) ~/ totalColumn && i < posts.length;
        row++) {
//      print(
//          "_buildGrid ${posts.length}::: ${posts.length~/ totalColumn} row=$row");
      List<Widget> pictures = new List();
      for (int j = 0; j < totalColumn; j++) {
        pictures.add(
            i < posts.length ? _buildPicture(posts[i++]) : _buildPicture(null));
      }

      rows.add(new Row(
        key: row == 0 ? key : null,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: createRowChildrenWithPadding(
            pictures,
            new Padding(
              padding: EdgeInsets.only(right: _padding),
            )),
      ));
    }

    return new Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: rows,
    );
  }

  Map<DateTime, List<Post>> generateDateToPosts(List<Post> posts) {
    Map<DateTime, List<Post>> map = new Map<DateTime, List<Post>>();
    posts.forEach((Post post) {
      DateTime date = new DateTime(
          post.createdTime.year,
          post.createdTime.month,
          _viewBy == ViewBy.month ? 1 : post.createdTime.day);
      if (map.containsKey(date)) {
        map[date].add(post);
      } else {
        map[date] = [post];
      }
    });
    return map;
  }

  Future<Null> handleDBRefresh() async {
    List<Post> refreshedPost = await InstapostDatabase.get().getPosts();
    if (mounted) {
      setState(() {
        posts = refreshedPost;
        _selectedDate = null;
//        _offsetCalculation = OffsetCalculation.none;
//        updateCaptionHeights();
      });
    }
    return null;
  }

  Future<Null> _handleRefresh() async {
    await DataSyncer.get().refresh(() {});
    List<Post> refreshedPost = await InstapostDatabase.get().getPosts();
    setState(() {
      posts = refreshedPost;
      _selectedDate = null;
//      _offsetCalculation = OffsetCalculation.none;
//      updateCaptionHeights();
    });
    return null;
  }

  Future<Null> selectDateFromPicker() async {
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
        Scaffold.of(context).showSnackBar(new SnackBar(content: new Text("hello ${dateToString(selected)}")));
      });
    }
  }
}

class DissapearingProgressBar extends StatelessWidget {
  final int _count;
  final int _total;
  final AnimationController _animationController;

  DissapearingProgressBar(this._count, this._total, this._animationController);

  @override
  Widget build(BuildContext context) {
    print("build DissapearingProgressBar with ${_count}");
    /* animation
    return new SizeTransition(
        sizeFactor: new Tween(begin: 1.0, end: 0.0).animate(new CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        )),
        axisAlignment: -1.0,
    */
    return new SlideTransition(
        position: new Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, -1.0),
        ).animate(new CurvedAnimation(
          parent: _animationController,
          curve: Curves.fastOutSlowIn,
        )),
        child: new Opacity(
            opacity: 0.7,
            child: new Stack(
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  new Container(
                      height: 40.0,
                      child: new LinearProgressIndicator(
                        value: _count / _total,
                        backgroundColor: Colors.white,
                      )),
                  new Text("$_count/$_total")
                ])));
  }
}

AppBar createAppBar(User user, selectDateFromPickerCallback,
    {viewByDayCallback, viewByMonthCallBack}) {
  List<PopupMenuEntry<String>> popupActions = new List();
  if (viewByDayCallback != null) {
    popupActions.add(new PopupMenuItem<String>(
        value: "",
        child: new FlatButton(
            child: const Text('View by Day'),
            onPressed: () {
              print("view by day");
              viewByDayCallback();
            })));
  }
  if (viewByMonthCallBack != null) {
    popupActions.add(new PopupMenuItem<String>(
        value: "",
        child: new FlatButton(
            child: const Text('View by Month'),
            onPressed: () {
              print("view by month");
              viewByMonthCallBack();
            })));
  }

  return new AppBar(
      titleSpacing: 5.0,
      title: new Row(children: <Widget>[
        new CircleAvatar(
          backgroundImage: new NetworkImage(user.profilePicture),
        ),
        new Container(
            margin: new EdgeInsets.all(2.0), child: new Text(user.username))
      ]),
      actions: <Widget>[
        new IconButton(
          onPressed: () {
            print("datetime picker pressed");
            selectDateFromPickerCallback();
          },
          icon: new Icon(Icons.calendar_today),
        ),
        new PopupMenuButton<String>(
            onSelected: null,
            itemBuilder: (BuildContext context) {
              popupActions.addAll([
                new PopupMenuItem<String>(
                    value: "",
                    child: new FlatButton(
                        child: const Text('DATABASE'),
                        onPressed: () {
                          print("check database actions");
                          Navigator.of(context).pushNamed("/database");
                        })),
                new PopupMenuItem<String>(
                    value: "",
                    child: new FlatButton(
                        child: const Text('Logout...'),
                        onPressed: () {
                          print("logout on pressed");
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              "/logout", (Route<dynamic> route) => false);
                        })),
                new PopupMenuItem<String>(
                    value: "",
                    child: new FlatButton(
                        child: const Text('Exit...'),
                        onPressed: () {
                          print("exit on pressed");
                          exit(0);
                        }))
              ]);
              return popupActions;
            })
      ]);
}
