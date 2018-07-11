import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:instagram/instagram.dart';
import 'package:flutter/foundation.dart';

import 'dart:async';
import 'dart:io';

import 'package:pastdate/models.dart';

typedef Future<List<Media>> GetNextMedia({String nextId});

class InstapostDatabase extends ChangeNotifier {

  static final InstapostDatabase _instapostDatabase =
      new InstapostDatabase._internal();

  InstapostDatabase._internal();

  final instapostsDbName = ".insta.db";

  Database db;
  final String tablePosts = "posts";
  final String tableMedia = "media";
//  final String tableCarousel = "carousel";

  static InstapostDatabase get() {
    return _instapostDatabase;
  }

  Future<Null> initialise(String username, [VoidCallback listener]) async {
    print("InstapostDatabase init");
    if (listener != null) {
      addListener(listener);
    }

    String path = await getPathToDB(username);
    print("InstapostDatabase path to db $path");
    // Make sure the directory exists

    db = await openDatabase(path, version: 2,
        onCreate: (Database db, int version) async {
      print("onCreate version=$version");
      var sql1 = "CREATE TABLE IF NOT EXISTS $tablePosts "
          "("
          "${Post.db_postId} TEXT PRIMARY KEY, "
          "${Post.db_link} TEXT NOT NULL, "
          "${Post.db_thumbnailUrl} TEXT NOT NULL, "
          "${Post.db_createdTime} TEXT NOT NULL, "
          "${Post.db_type} TEXT NOT NULL, "
          "${Post.db_caption} TEXT NOT NULL "
          ")";
      print("onCreate database: $sql1");
      await db.execute(sql1);
      var sql2 = "CREATE TABLE IF NOT EXISTS $tableMedia "
          "("
          "${PostMedia.db_id} INTEGER PRIMARY KEY, "
          "${PostMedia.db_postId} TEXT NOT NULL, "
          "${PostMedia.db_type} TEXT NOT NULL, "
          "${PostMedia.db_imageUrl} TEXT NOT NULL, "
          "${PostMedia.db_width} REAL NOT NULL, "
          "${PostMedia.db_height} REAL NOT NULL, "
          "${PostMedia.db_order} INT NOT NULL, "
          "FOREIGN KEY (${PostMedia.db_postId}) REFERENCES ${tablePosts}(${Post.db_postId}) ON DELETE CASCADE "
          ")";
      print("onCreate database: $sql2");
      await db.execute(sql2);
    }, onOpen: (Database db) async {
      List<Map> result = await db.rawQuery("pragma table_info($tablePosts)");
      print("result $result");

      print("onOpen: done");
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      // Database version is updated, alter the table


    });

//    List<Map> result = await db.rawQuery("pragma table_info($tableName)");
//    print("result $result");
    List<Map> result =  await db.rawQuery("select sqlite_version()");
    print("result $result");
    notifyListeners();
  }

  Future<Post> getPost(String id) async {
    var result = await db.rawQuery('SELECT * FROM $tablePosts p '
        'INNER JOIN $tableMedia m ON p.${Post.db_postId} = m.${PostMedia.db_postId}'
        ' WHERE p.${Post.db_postId} = "$id" '
        'ORDER BY m.${PostMedia.db_order}');
    if (result.length == 0) return null;
    Post post = new Post.fromMap(result[0]);

    post.media = result.map((Map<String, dynamic> map) {
      return new PostMedia.fromMap(map);
    }).toList();
    return post;
  }

  Future<List<PostMedia>> getMedia(Post post) async {
    List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT * FROM $tableMedia WHERE ${PostMedia.db_postId} = "${post.postId}"');

    List<PostMedia> media = result.map((Map<String, dynamic> map) {
      return new PostMedia.fromMap(map);
    }).toList();

    print("get media for post ${post.postId} =${media.length}");
    return media;
  }

/*
  Future<Map<String, List<String>>> _getCarousels() async {
    List<Map<String, dynamic>> result = await db
        .rawQuery('SELECT * FROM $tableCarousel order by ${Post.db_postId}');

    Map<String, List<String>> carousels = new Map();
    for (Map<String, dynamic> row in result) {
      String postId = row[Post.db_postId];
      String url = row[Post.db_imageurl];
      List<String> urls = carousels[postId];
      if (urls == null) {
        carousels[postId] = [url];
      } else {
        urls.add(url);
      }
    }

    return carousels;
  }
*/

  Future<List<Post>> getPosts() async {
    var sql = 'SELECT * FROM $tablePosts p '
        'INNER JOIN $tableMedia m ON p.${Post.db_postId} = m.${PostMedia.db_postId} '
        'ORDER BY datetime(${Post.db_createdTime}) DESC, m.${PostMedia.db_order} ASC';
    print("$sql");
    List<Map> results = await db.rawQuery(sql);

    Map<String, Post> posts = new Map();
//        new List.generate(listOfMap == null ? 0 : listOfMap.length, (index) {
//      Post post = new Post.fromMap(listOfMap[index]);
//      return post;
//    });
    for (Map result in results) {
      String postId = result[Post.db_postId];
      Post post = posts[postId];
      if (post == null) {
        post = new Post.fromMap(result);
        posts[postId] = post;
      }
      PostMedia media = new PostMedia.fromMap(result);
      //it was ordered by 'order' so i'm sure it's right order
      post.media.add(media);
    }

    print("getPosts() length ${posts?.length}");
    return new List.from(posts.values);
  }

  Future<Post> getLastPost() async {
    List<Map> result = await db.rawQuery(
        'SELECT * FROM $tablePosts ORDER BY datetime(${Post.db_createdTime}) DESC LIMIT 1');
    if (result.length == 0) return null;
    Post post = new Post.fromMap(result[0]);
    //though it's possible to make in 1 select
    post.media = await getMedia(post);
    return post;
  }

  Future _addPost(Transaction txn, Post post) async {
    int id = await txn.insert(tablePosts, post.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    print("inserted post=${post.postId}: with id $id");

    for (int i = 0; i < post.media.length; i++) {
      PostMedia media = post.media[i];
      int id = await txn.insert(tableMedia, media.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      print("inserted media[$i]: with id $id for ${post.postId}");
    }
  }

  Future addPosts(List<Post> posts) async {
    await db.transaction((txn) async {
      for (Post post in posts) {
        print("Post=${post}");
        _addPost(txn, post);
      }
    });
    notifyListeners();
  }

  Future add(List<Media> media) async {
    await db.transaction((txn) async {
      for (int i = 0; i < media.length; i++) {
        Post post = new Post.fromMedia(media[i]);
        print("Post=${post}");
        _addPost(txn, post);
      }
    });
    notifyListeners();
  }

  Future addAll(GetNextMedia f, {String nextId}) async {
    print("addAll called with nextId=$nextId");
    List<Media> media;
    if (nextId == null) {
      media = await f();
    } else {
      media = await f(nextId: nextId);
    }

    if (media.isEmpty) {
      print("media is empty. All data is inserted");
      return Future;
    }
    await add(media);
    nextId = media.last.id;
    //recursive call
    await addAll(f, nextId: nextId);
  }

  Future<int> count() async {
    return Sqflite
        .firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM $tablePosts"));
  }

  Future removeLast(int howmany) async {
    String sql = "DELETE FROM $tablePosts WHERE ${Post.db_postId} in "
        "( SELECT ${Post.db_postId} FROM $tablePosts "
        "ORDER BY datetime(${Post.db_createdTime}) "
        "DESC LIMIT $howmany)";
    int deletedCount = await db.rawDelete(sql);
    print("deleted $deletedCount rows from $tablePosts");
    notifyListeners();
  }

  Future cleanTable() async {
    int deletedCount1 = await db.delete(tableMedia, where: "1");
    int deletedCount2 = await db.delete(tablePosts, where: "1");
    print("deleted $deletedCount1 rows from $tableMedia");
    print("deleted $deletedCount2 rows from $tablePosts");

    notifyListeners();
  }

  Future deleteDB(String username) async {
    String path = await getPathToDB(username);

    await deleteDatabase(path);
    print("DB is deleted from $path");

    final myDir = new Directory(path);
    myDir.exists().then((isThere) {
      isThere ? print('path exists') : print('path non-existent');
    });
  }

  Future<String> getPathToDB(String username) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, username + instapostsDbName);
    await documentsDirectory.create(recursive: true);
    print("InstapostDatabase path to db is created");
    return path;
  }
}
