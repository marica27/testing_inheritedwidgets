import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as  http;
import 'package:instagram/instagram.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'pages/home.page.dart';
import 'pages/login.page.dart';
import 'pages/post.page.dart';
import 'pages/grid.page.dart';
import 'pages/database.test.page.dart';
import 'package:pastdate/models.dart';
import 'services/auth.service.dart';
import 'services/constants.dart';
import 'services/data.syncer.dart';
import 'services/database.dart';

// TODO: problem -  flatbutton occupyes only part of meny item.
// TODO: make login page with async loading

AuthService authService = new AuthService();

void main() async {
  CacheManager.showDebugLogs = true;

  // Get result of the login function.
  bool _isUserLoggedIn = await authService.isUserLoggedIn();

  Widget _defaultHome;
  if (_isUserLoggedIn) {
    _defaultHome = AsyncGridPage(); //new GridPage();
  } else {
    _defaultHome = new LoginPage();
  }

  // Run app!
  runApp(new MaterialApp(
    title: 'PastPost',
    theme: ThemeData.light(),
    home: _defaultHome,
    routes: <String, WidgetBuilder>{
      '/home': (BuildContext context) => new AsyncGridPage(),
      '/login': (BuildContext context) => new LoginPage(),
      '/logout': (BuildContext context) => new LogoutPage(),
      '/database': (BuildContext context) => new TestDatabase(),
    },
  ));
}


