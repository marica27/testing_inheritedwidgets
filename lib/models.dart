import 'package:meta/meta.dart';
import 'dart:core';
import 'package:instagram/instagram.dart';

import 'package:pastdate/services/database.dart';

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

  List<PostMedia> media = new List();

  Post(
      {@required this.postId,
      @required this.link,
      @required this.thumbnailUrl,
      @required this.createdTime,
      @required this.type,
      @required this.caption});

  Post.fromMedia(Media m) {
    this.postId = m.id;
    this.link = m.link;
    this.thumbnailUrl = m.images.thumbnail.url;
    this.createdTime = m.createdTime;
    this.type = m.type;
    this.caption = m.caption.text;

    if (type == MediaType.carousel && m.carouselMedia.length > 0) {
      for (int i = 0; i < m.carouselMedia.length; i++) {
        Media carouselMedia = m.carouselMedia[i];
        if (carouselMedia.type == MediaType.video) {
          this.media.add(new PostMedia.fromMediaImage(
              postId: m.id,
              order: i,
              type: carouselMedia.type,
              media: carouselMedia.videos.standardResolution));
        } else {
          this.media.add(new PostMedia.fromMediaImage(
              postId: m.id,
              order: i,
              type: carouselMedia.type,
              media: carouselMedia.images.standardResolution));
        }
      }
    } else {
      if (m.type == MediaType.video) {
        this.media = [
          new PostMedia.fromMediaImage(
              postId: m.id, type: m.type, media: m.videos.standardResolution)
        ];
      } else {
        this.media = [
          new PostMedia.fromMediaImage(
              postId: m.id, type: m.type, media: m.images.standardResolution)
        ];
      }
    }
  }

  Post.fromMap(Map<String, dynamic> map)
      : this(
          postId: map[db_postId].toString(),
          link: map[db_link],
          thumbnailUrl: map[db_thumbnailUrl],
          createdTime: DateTime.parse(map[db_createdTime]),
          type: map[db_type],
          caption: map[db_caption],
        );

  bool isCarousel() {
    return type == MediaType.carousel;
  }

  bool isVideo() {
    return type == MediaType.video;
  }

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
    return toMap().toString() + " ${media.length} ${media}";
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
      @required MediaImage media}) {
    this.postId = postId;
    this.type = type;
    this.imageUrl = media.url;
    this.width = media.width * 1.0;
    this.height = media.height * 1.0;
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

