import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram/instagram.dart';
import 'package:async_loader/async_loader.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/auth.service.dart';
import 'post.page.dart';
import 'list.page.dart';
import 'home.page.dart';
import '../services/database.dart';
import '../services/models.dart';
import '../services/data.syncer.dart';

class TestDatabase extends StatefulWidget {
  @override
  TestDatabaseState createState() => new TestDatabaseState();
}

class TestDatabaseState extends State<TestDatabase> {
  int _count;
  List<Post> _posts;

  static const username = "maricakuz";

  void initState() {
    print("TestDatabaseState init state");
    super.initState();
    InstapostDatabase.get().initialise(username, refreshCount);
  }

  void refreshCount() async {
    int count = await InstapostDatabase.get().count();
    if (mounted) {
      setState(() {
        print("set state TestDatabaseState for new count $_count");
        _count = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("build TestDatabaseState with count $_count");

    return new Scaffold(
      appBar: createAppBar("username", null),
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          new Text("counts : $_count Posts ${_posts?.length}"),
          new RaisedButton(
              child: const Text('add to db from appAuth.getMedia()'),
              onPressed: () async {
                List<Media> media = await authService.getMedia();
                print("got media ${media.length}");
                await InstapostDatabase.get().add(media);
                print("it was added");
              }),
          new Container(
            height: 5.0,
          ),
          new RaisedButton(
              child: const Text('fill DB with copies'),
              onPressed: () async {
                await fillDBwithCopies();
                print("fillDBwithCopies: done");
              }),
          new Container(
            height: 5.0,
          ),
          new RaisedButton(
              child: const Text('FIX DATA'),
              onPressed: () async {
                await fixData();
                print("fix data: done");
              }),
          new Container(
            height: 5.0,
          ),
          new RaisedButton(
              child: const Text('add to db from getAlotGeneratedMedia'),
              onPressed: () async {
                await InstapostDatabase.get().addAll(getAlotGeneratedMedia);
                print("it was added by getAlotGeneratedMedia");
              }),
          new Container(
            height: 5.0,
          ),
          new RaisedButton(
              child: const Text("REFRESH"),
              onPressed: () {
                DataSyncer.get().refresh(refreshCount);
              }),
          new Container(
            height: 5.0,
          ),
          new RaisedButton(
              child: const Text("remove last 10"),
              onPressed: () async {
                InstapostDatabase.get().removeLast(10);
              }),
          new Container(
            height: 5.0,
          ),
          new RaisedButton(
              child: const Text("clean table"),
              onPressed: () {
                InstapostDatabase.get().cleanTable();
              }),
          new Container(
            height: 5.0,
          ),
          new RaisedButton(
              child: const Text("delete DB"),
              onPressed: () async {
                await InstapostDatabase.get().deleteDB(username);
//                await InstapostDatabase
//                    .get()
//                    .initialise(username, refreshCount);
              }),
          new Container(
            height: 5.0,
          ),
          new RaisedButton(
              child: const Text("remove SYNC key"),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove(DataSyncer.syncedKey);
                print("remove ${DataSyncer.syncedKey}");
              }),
          new Container(
            height: 5.0,
          ),
          new RaisedButton(
              child: const Text("del DB & remove SYNC key"),
              onPressed: () async {
                await InstapostDatabase.get().deleteDB(username);
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove(DataSyncer.syncedKey);
                print("remove ${DataSyncer.syncedKey}");
              }),
          new Container(
            height: 5.0,
          ),
          new RaisedButton(
              child: const Text("delete ALL & exit"),
              onPressed: () async {
                await InstapostDatabase.get().deleteDB(username);
                SharedPreferences prefs = await SharedPreferences.getInstance();

                await prefs.remove(AuthService.userKey);
                await prefs.remove(AuthService.accessTokenKey);
                await prefs.remove(DataSyncer.syncedKey);
                await prefs.clear();
                setState(() {
                  print("delete ALL is done");
                  _count = 0;
                  new Future.delayed(new Duration(seconds: 2), () {
                    print("exit...");
                    exit(1);
                  });
                });
              }),
          new Container(
            height: 20.0,
          ),
          new RaisedButton(
              child: const Text("show data"),
              onPressed: () async {
                List<Post> posts = await InstapostDatabase.get().getPosts();
                setState(() {
                  print("load _posts onPressed");
                  _posts = posts;
                });
              }),
          new Container(
              key: new Key("posts"),
              child: _posts == null
                  ? const Text("posts are here")
                  : new Expanded(
                      child: new ListView.builder(
                          key: new Key("posts"),
                          itemCount: _posts.length,
                          itemBuilder: (context, i) {
                            return new ListTile(
                              title: new Text(_posts[i].postId),
                              subtitle: new Text(_posts[i].link),
                              trailing: new Text(
                                  _posts[i].createdTime.toIso8601String()),
                            );
                          }))),
        ],
      ),
    );
  }

  Future<List<Media>> getLittleMediaFromIG({String nextId}) async {
    List<Media> media = await authService.getMedia(count: 8, nextId: nextId);
    print("databaseTest: get ${media.length} from appAuth");
    return new Future(() {
      return media;
    });
  }

  Future<List<Media>> getAlotGeneratedMedia({String nextId}) async {
    int nextIdInt = nextId == null ? 0 : int.parse(nextId.substring(3));
    if (nextIdInt > 300) {
      return new List<Media>();
    }
    nextIdInt++;
    var now = new DateTime.now();
    List<Media> media = new List.generate(10, (index) {
      return new Media(
          id: "id_${index + nextIdInt}",
          type: MediaType.image,
          filter: "",
          link: "https://www.instagram.com/p/BicnwHyBBRa/",
          images: new MediaImages(
              thumbnail: new MediaImage(
                  url:
                      "https://scontent.cdninstagram.com/vp/d89e8b0dbe2f23266c4a77cf67b1db89/5B9CC404/t51.2885-15/s150x150/e35/31672756_229797691106443_8815431005084057600_n.jpg",
                  width: 150,
                  height: 150)),
          createdTime: now.subtract(new Duration(days: (index + nextIdInt))));
    }, growable: true);
    print(
        "getAlotGeneratedMedia with $nextId: media generated from ${media.first.id} to ${media.last.id}");

    return Future.delayed(const Duration(seconds: 1), () => media);
  }

  static Future<Null> fillDBwithCopies() async {
    List<Media> media = await authService.getMedia();
    print("got media ${media.length}");
    await InstapostDatabase.get().add(media);

    List<Post> posts = await InstapostDatabase.get().getPosts();
    DateTime last = posts.last.createdTime;

    var random = new Random();
    
    for (int i = 0, cycle = 0; i < 2200; cycle++) {
      List<Post> newPosts = new List();
      for (int j = 0; j < posts.length; j++, i++) {
        DateTime date = j > 0 && posts[j].createdTime.day == posts[j-1].createdTime.day ?
        last.subtract(new Duration(days: j+i-1)) : last.subtract(new Duration(days: j+i));
        Post post = new Post(
            postId: "id_$i",
            caption: posts[j].caption,
            createdTime: last.subtract(new Duration(days: j+cycle)),
            link: posts[j].link,
            thumbnailUrl: posts[j].thumbnailUrl,
            type: posts[j].type);

        post.media = new List();
        for (PostMedia mp in posts[j].media) {
          post.media.add(new PostMedia(
              postId: post.postId,
              imageUrl: mp.imageUrl,
              type: mp.type,
              width: mp.width,
              height: mp.height,
              order: mp.order));
        }
        //print("createdTime=${post.createdTime.toIso8601String()}");
        newPosts.add(post);
      }
      print("new posts generated i=$i ");
      await InstapostDatabase.get().addPosts(newPosts);
    }
  }

  Future<Null> fixData() async {}
}
