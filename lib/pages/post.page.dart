import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram/instagram.dart';
import 'package:async_loader/async_loader.dart';
import 'package:date_format/date_format.dart';
import 'package:carousel/carousel.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

import '../main.dart';
import 'video.dart';
import '../services/auth.service.dart';
import 'home.page.dart';
import 'package:pastdate/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PostPage extends StatefulWidget {
  Post post;

  PostPage(this.post, {Key key}) : super(key: key);

  @override
  PostPageState createState() => new PostPageState(post);
}

class PostPageState extends State<PostPage>
    with SingleTickerProviderStateMixin {
  Post post;
  TabController tabController;

  PostPageState(this.post);

  initState() {
    if (post.isCarousel()) {
      tabController = new TabController(length: post.media.length, vsync: this);
    }
  }

  static double height = 8.0 + 8.0 + 6.0 + 8.0 + 8.0 + 32.0;

  @override
  Widget build(BuildContext context) {
    //print("post page ${post}");
    Widget textSection = new PostCaption(post.caption);

    Widget barSection;
    if (post.type == MediaType.carousel) {
      barSection = new Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: new Center(
              child: new TabPageSelector(
            controller: tabController,
            indicatorSize: 6.0,
          )));
    }

    Widget dateSection = new Container(
      padding: const EdgeInsets.all(8.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          new Text(formatDate(
              post.createdTime, [d, '-', M, '-', yyyy, ' ', HH, ':', nn]))
        ],
      ),
    );

    Widget imageSection;
    if (post.type == MediaType.carousel) {
      imageSection = new AspectRatio(
        aspectRatio: post.media.first.width / post.media.first.height,
        child: new TabBarView(
          children: post.media.map((PostMedia media) {
            return buildImageOrVideo(media.imageUrl);
          }).toList(),
          controller: tabController,
        ),
      );
    } else {
      imageSection = buildImageOrVideo(post.media.first.imageUrl);
    }

    List<Widget> children = barSection == null
        ? [dateSection, imageSection, textSection]
        : [
            dateSection,
            imageSection,
            barSection,
            textSection
          ];

    return new Container(
        margin: const EdgeInsets.only(bottom: 32.0),
        child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children));
  }

  Widget buildImageOrVideo(String url) {
    if (url.endsWith("mp4")) {
      return new Video(url);
    }
    double width = MediaQuery.of(context).size.width;
    double heigh = width / post.media.first.width * post.media.first.height;
    return new CachedNetworkImage(
        imageUrl: url,
        placeholder: new Container(
            height: width,
            width: width,
            alignment: Alignment.center,
            child: new Container(
                height: heigh,
                width: width,
                color: Colors.grey[200])
        ));
  }
}

class PostCaption extends StatelessWidget {
  String caption;

  PostCaption(this.caption, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var matches = new RegExp(r"#\S+|@\w+").allMatches(caption);
    //print("formatCaption:${matches.length}");

    List<TextSpan> spans = new List();
    int start = 0;
    for (Match m in matches) {
      if (m.start != start) {
        String text = caption.substring(start, m.start);
        spans.add(new TextSpan(text: text));
      }
      String hashtagOrUsername = caption.substring(m.start, m.end);
      spans.add(new TextSpan(
        text: hashtagOrUsername,
        style: new TextStyle(color: Theme.of(context).accentColor),
//          recognizer: new TapGestureRecognizer()
//            ..onTap = () {
//              launch(
//                  'https://www.instagram.com/$hashtagOrUsername/');
//            }
      ));
      start = m.end;
    }
    if (start < caption.length) {
      String text = caption.substring(start);
      spans.add(new TextSpan(text: text));
    }

    return new Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new RichText(
          softWrap: true,
          textAlign: TextAlign.start,
          text: new TextSpan(
            text: '',
            style: DefaultTextStyle.of(context).style,
            children: spans,
          ),
        ));
  }
}
