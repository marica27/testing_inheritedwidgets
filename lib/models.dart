import 'package:meta/meta.dart';
import 'dart:core';
//import 'package:instagram/instagram.dart';

enum VisibleAction { day, month, instaview }
enum FirstLoadState { none, process, failure, finisn }


class AppState {
  bool isLoading;
  String accessToken;
  User user;
  List<Post> posts;
  FirstLoadState firstLoadState;
  VisibleAction visibleAction;
  DateTime selectedDate;

  factory AppState.loading() => AppState(isLoading: true);

  AppState({
    this.isLoading = false,
    this.accessToken,
    this.user,
    this.posts = const [],
    this.firstLoadState = FirstLoadState.finisn,
    this.visibleAction = VisibleAction.day,
    this.selectedDate,
  });

  clearPosts() => posts = [];

  bool isUserLoggedIn() => user != null;


  @override
  String toString() {
    return 'AppState{isLoading: $isLoading, accessToken: $accessToken, user: $user, posts: $posts, firstLoadState: $firstLoadState, visibleAction: $visibleAction, selectedDate: $selectedDate}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          posts == other.posts &&
          firstLoadState == other.firstLoadState &&
          visibleAction == other.visibleAction &&
          selectedDate == other.selectedDate;

  @override
  int get hashCode =>
      user.hashCode ^
      posts.hashCode ^
      firstLoadState.hashCode ^
      visibleAction.hashCode ^
      selectedDate.hashCode;
}

class User {
  String username;
  User({this.username});
}

class Post {
  static final db_postId = "post_id";
  static final db_link = "link";
  static final db_thumbnailUrl = "thumbnail_url";
  static final db_createdTime = "created_time";
  static final db_type = "post_type";
  static final db_caption = "caption";

  String postId, link, thumbnailUrl, type, caption;
  DateTime createdTime;

  bool captionHeightChanged = false;

//  List<PostMedia> media = new List();

  Post(
      {@required this.postId,
      @required this.link,
      @required this.thumbnailUrl,
      @required this.createdTime,
      @required this.type,
      @required this.caption});


  Post.fromMap(Map<String, dynamic> map)
      : this(
          postId: map[db_postId].toString(),
          link: map[db_link],
          thumbnailUrl: map[db_thumbnailUrl],
          createdTime: DateTime.parse(map[db_createdTime]),
          type: map[db_type],
          caption: map[db_caption],
        );


  Map<String, dynamic> toMap() {
    return {
      db_postId: postId,
      db_link: link,
      db_thumbnailUrl: thumbnailUrl,
      db_createdTime: createdTime.toIso8601String(),
      db_type: type,
      db_caption: caption,
    };
  }

  String toString() {
    return toMap().toString();
  }

  bool operator ==(other) {
    return (other is Post && other.postId == this.postId);
  }

  int get hashCode => this.postId.hashCode;
}

class PostMedia {
  static final db_id = "id";
  static final db_postId = "post_id";
  static final db_type = "type";
  static final db_imageUrl = "image_url";
  static final db_height = "height";
  static final db_width = "width";
  static final db_order = "number";

  int id, order;

  String postId, imageUrl, type;
  double width, height;

  PostMedia(
      {this.id,
      @required this.postId,
      @required this.imageUrl,
      @required this.type,
      @required this.width,
      @required this.height,
      @required this.order = 0});

  PostMedia.fromMediaImage(
      {@required String postId,
      int order = 0,
      @required String type,
     }) {
    this.postId = postId;
    this.type = type;
    this.imageUrl = "";
    this.width = 1.0;
    this.height =  1.0;
    this.order = order;
  }

  PostMedia.fromMap(Map<String, dynamic> map)
      : this(
          id: map[db_id],
          postId: map[db_postId],
          imageUrl: map[db_imageUrl],
          type: map[db_type],
          height: map[db_height],
          width: map[db_width],
          order: map[db_order],
        );

  Map<String, dynamic> toMap() {
    return {
      db_postId: postId,
      db_type: type,
      db_imageUrl: imageUrl,
      db_width: width,
      db_height: height,
      db_order: order,
    };
  }

  String toString() {
    return toMap().toString();
  }
}
