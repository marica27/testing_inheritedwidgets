import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram/instagram.dart';
import 'package:async_loader/async_loader.dart';
//import 'package:date_utils/date_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/auth.service.dart';
import '../services/database.dart';
import '../services/models.dart';
import '../pages/post.page.dart';
import '../pages/list.page.dart';
import '../pages/database.test.page.dart';

class DataSyncer {
  static final DataSyncer _dataSyncer = new DataSyncer._internal();
  static const syncedKey = "all_data_loaded";

  DataSyncer._internal();

  static DataSyncer get() {
    return _dataSyncer;
  }

  factory DataSyncer() {
    return _dataSyncer;
  }

  Future<bool> wasDataLoadedAlready() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(syncedKey);
  }

  //as it's impossible for user to change createdTime of the post
  //we can get last post from DB and fetch data from instagram
  //untill createdTime is before or the same as in last post
  Future refresh(callbackAfterFinish) async {
    AuthService authService = AuthService.get();
    InstapostDatabase instaDB = InstapostDatabase.get();
    Post post = await instaDB.getLastPost();
    if (post == null) {
      makeSync(callbackAfterFinish: callbackAfterFinish);
    } else {
      DateTime lastSavedInDB = post.createdTime;
      print("refresh: lastSaved ${lastSavedInDB.toIso8601String()} ");
      List<Media> media = await _getMediaFromIG();
      await _recursiveRefresh(lastSavedInDB, media);
      callbackAfterFinish();
    }
  }

  Future _recursiveRefresh(DateTime lastSavedInDB, List<Media> media) async {
    print("_recursiveRefresh: first ${media.first.createdTime} last ${media.last.createdTime}");
    await InstapostDatabase.get().add(media);
    if (media.last.createdTime.isAfter(lastSavedInDB)) {
      List<Media> newMedia = await _getMediaFromIG(nextId: media.last.id);
      await _recursiveRefresh(lastSavedInDB, newMedia);
    }
  }

  //check property does it synced everything
  //if not so - app laucnhed first time or was not sync completly
  //database make insert or replace, so it is safe to fetch saved data
  //if counts in db and user.media is not the same - try again
  //clean db and call again - in this case user will see that all data are gone and fetch again - strange(!)
  void makeSync({void callbackBefore(), void callbackAfterEachBatch(), void callbackAfterFinish()}) async {
    final prefs = await SharedPreferences.getInstance();
    var synced = prefs.getBool(syncedKey);
    print("makeSync synced=$synced");
    if (synced == null || !synced) {
      if (callbackBefore != null) {
        callbackBefore();
      }
      //await loadAllDataFromInstagramToDatabase(callbackAfterEachBatch);
      InstapostDatabase.get().addListener(callbackAfterEachBatch);
      await TestDatabaseState.fillDBwithCopies();
      print("makeSync is finished. set flag $syncedKey");
      prefs.setBool(syncedKey, true);
      if (callbackAfterFinish != null) {
        print("call callbackAfterFinish");
        callbackAfterFinish();
      }
    }
  }

  Future loadAllDataFromInstagramToDatabase(callbackAfterEachBatch) async {
    AuthService authService = AuthService.get();
    InstapostDatabase instaDB = InstapostDatabase.get();

    instaDB.addListener(callbackAfterEachBatch);
    await instaDB.addAll(_getMediaFromIG);
    //instaDB.removeListener(callbackAfterEachBatch);
  }

  //count = 8 and Duration is only for SANDBOX mode of Instagram API
  Future<List<Media>> _getMediaFromIG({String nextId}) async {
    List<Media> media = await authService.getMedia(count: 8, nextId: nextId);
    print("DataSyncer: get ${media.length} from authService");
//    return new Future.delayed(new Duration(seconds: 2), () {
//      return media;
//    });
  return media;
  }

  Future<bool> checkCountDatabaseAndInstagramPost() async {
    AuthService authService = AuthService.get();
    InstapostDatabase instaDB = InstapostDatabase.get();
    //change to Future.wait([authService.getUser(), instaDB.count()]).then();
    User user = await authService.getUser();
    int count = await instaDB.count();
    print("database count=$count instagram count=${user.counts.media}");
    return count == user.counts.media;
  }
}
