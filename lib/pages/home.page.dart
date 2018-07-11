import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram/instagram.dart';
import 'package:async_loader/async_loader.dart';
//import 'package:date_utils/date_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../main.dart';
import '../services/auth.service.dart';
import '../services/database.dart';
import 'package:pastdate/models.dart';
import 'post.page.dart';
import 'list.page.dart';

final GlobalKey<AsyncLoaderState> _asyncLoaderStateHomePage =
    new GlobalKey<AsyncLoaderState>();

AsyncLoader createAsyncLoaderHomePage(String username) {
  AppBar appBar = createAppBar(username, () {
    print("createAsyncLoaderHomePage datetimepicker");
  });

  return new AsyncLoader(
    key: _asyncLoaderStateHomePage,
    initState: () async {
      await InstapostDatabase.get().initialise("maricakuz", () {});
      List<Post> posts = await InstapostDatabase.get().getPosts();
      //appAuth.getUserAndMedia(),
      return posts;
    },
    renderLoad: () => new Scaffold(
          appBar: appBar,
          body: new Center(child: new CircularProgressIndicator()),
        ),
    renderError: ([error]) => new Text('Sorry, there was an error loading'),
    renderSuccess: ({data}) => new HomePage(data),
  );
}

AppBar createAppBar(String username, selectDateFromPickerCallback) {
  AppBar appBar = new AppBar(
      title: new Text(username == null ? "Loading..." : username),
      actions: <Widget>[
        new IconButton(
          onPressed: () {
            print("datetime picker pressed");
            selectDateFromPickerCallback;
          },
          icon: new Icon(Icons.calendar_today),
        ),
        new PopupMenuButton<String>(
            onSelected: null,
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
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
              ];
            })
      ]);
  return appBar;
}

class HomePage extends StatefulWidget {
  User user;
  List<Media> media;
  List<Post> posts;

  HomePage(dynamic data) {
    if (data == null) {
      throw new Exception("data cannot be null");
    }

    if (data == UserAndMedia) {
      this.media = data.posts;
      this.user = data.user;

      this.posts = data.posts;
      posts = new List.generate(data.posts, (i) {
        Media m = data.posts[i];
        return new Post.fromMedia(m);
      });
    } else {
      this.user = new User(
          id: "id",
          username: "maricakuz",
          fullName: "mARICa",
          bio: "bio",
          website: "website",
          counts: new UserCounts(media: 1000, follows: 24, followedBy: 32));
      this.posts = data;
    }
    print("media ${this.posts.length}");
  }

  @override
  _HomePageState createState() =>
      new _HomePageState(this.user, this.posts, this.media);
}

class _HomePageState extends State<HomePage> {
  User user;
  List<Post> posts;
  List<Media> media;
  DateTime _selectedDate;
  ScrollController _scrollController;

  _HomePageState(this.user, this.posts, this.media);

  @override
  void initState() {
    super.initState();
    _scrollController = new ScrollController();
  }

  Future<Null> selectDateFromPicker() async {
    print("selected date $_selectedDate");
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
        print("selected date $_selectedDate");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double _ITEM_HEIGHT = 150.0 + 6;
    if (_selectedDate != null) {
      for (int i = 0, row = 0; i < posts.length; i++, row = i ~/ 3) {
        if (posts?.elementAt(i)?.createdTime.difference(_selectedDate).inDays ==
            0) {
          print("scroll to row $row ${posts.elementAt(i).postId}");
          _scrollController.animateTo(row * _ITEM_HEIGHT,
              duration: new Duration(seconds: 2), curve: Curves.ease);
          break;
        }
      }
    }

    return new Scaffold(
        appBar: new AppBar(
            title:
                new Text(user?.username == null ? "Loading..." : user.username),
            actions: <Widget>[
              new IconButton(
                onPressed: () {
                  print("datetime picker pressed");
                  selectDateFromPicker();
                },
                icon: new Icon(Icons.calendar_today),
              ),
              new PopupMenuButton<String>(
                  onSelected: null,
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
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
                    ];
                  })
            ]),
        body: new Scrollbar(
            child: new GridView.count(
                controller: _scrollController,
                crossAxisCount: 3,
                children: new List.generate(posts.length, (index) {
                  return new GestureDetector(
                      onTap: () =>
                          Navigator.of(context).push(new PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    new ListPage(user, posts, index),
                              )),
                      child: new Container(
                        margin: const EdgeInsets.all(3.0),
                        child: new CachedNetworkImage(
                          imageUrl: posts[index].media.first.imageUrl,
                          placeholder: new Container(
                              height: 150.0,
                              width: 150.0,
                              child: new CircularProgressIndicator()),
                          errorWidget: new Icon(Icons.error),
                        ),
                      ));
                }))));
  }
}

//<PopupMenuEntry<String>>[
//PopupMenuItem<String>(
//value: MenuTitle.day,
//child: new ListTile(
//leading: const Icon(Icons.calendar_view_day),
//title: Text('by day'))),
//PopupMenuItem<String>(
//value: MenuTitle.week,
//child: new ListTile(
//leading: const Icon(Icons.view_week),
//title: Text('by week'))),
//PopupMenuItem<String>(
//value: MenuTitle.month,
//child: new ListTile(
//leading: const Icon(Icons.calendar_today),
//title: Text('by month'))),
//PopupMenuDivider(), // ignore: list_element_type_not_assignable, https://github.com/flutter/flutter/issues/5771
//PopupMenuItem<String>(
//value: MenuTitle.logout,
//child: new ListTile(
//leading: const Icon(Icons.verified_user),
//title: Text('Logout'),
//onTap: () {
//print("login onTapped");
//})),
//PopupMenuItem<String>(
//value: MenuTitle.about,
//child: new ListTile(
////leading: const Icon(Icons.verified_user),
//title: Text('About'))),
//PopupMenuItem<String>(
//value: MenuTitle.exit,
//child: new ListTile(
//leading: const Icon(Icons.exit_to_app),
//title: Text('Exit')))
//])
