import 'package:flutter/material.dart';
import 'package:async_loader/async_loader.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../services/constants.dart';
import '../services/database.dart';
import '../services/data.syncer.dart';
import 'grid.page.dart';
import 'package:instagram/instagram.dart';

class LogoutPage extends StatelessWidget {
  LogoutPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //It remove token from cache and make InstagramApi null
    authService.logout();

    var raisedButton = new RaisedButton(
      child: const Text('Login with Instagram'),
      color: Theme.of(context).accentColor,
      elevation: 4.0,
      splashColor: Colors.blueGrey,
      onPressed: () {
        Navigator
            .of(context)
            .pushNamedAndRemoveUntil("/login", (Route<dynamic> route) => false);
      },
    );
    var message = new Text(
      "PastPost disconnected from your instagram account",
      style: new TextStyle(
        color: Colors.green[300],
      ),
    );
    return new Scaffold(
      appBar: new AppBar(title: const Text("Past Post")),
      body: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[message, raisedButton]),
    );
  }
}

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Instance of WebView plugin
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  String token;

  // On destroy stream
  StreamSubscription _onDestroy;

  // On urlChanged stream
  StreamSubscription<String> _onUrlChanged;

  // On urlChanged stream
  StreamSubscription<WebViewStateChanged> _onStateChanged;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();

  @override
  initState() {
    super.initState();

    flutterWebviewPlugin.close();

    // Add a listener to on destroy WebView, so you can make came actions.
    _onDestroy = flutterWebviewPlugin.onDestroy.listen((_) {
      if (mounted) {
        // Actions like show a info toast.

      }
    });

    // Add a listener to on url changed
    _onUrlChanged = flutterWebviewPlugin.onUrlChanged.listen((String url) {
      if (mounted) {
        setState(() {
          print("URL changed: $url");
          if (url.startsWith(Constants.redirectUri)) {
            RegExp regExp = new RegExp("#access_token=(.*)");
            this.token = regExp.firstMatch(url)?.group(1);
            print("token $token");
            if (token == null) {
              print("error token is null");
              //todo: show error message
            }
            authService.keepToken(token).then((Null) async {
              authService.initialise(token);
              User user = await authService.getUser();
              authService.keepUser(user);
              await InstapostDatabase.get().initialise(user.username);
              Navigator.of(context).pushNamedAndRemoveUntil(
                  "/home", (Route<dynamic> route) => false);
              flutterWebviewPlugin.close();
            });

          }
        });
      }
    });
  }

  @override
  void dispose() {
    // Every listener should be canceled, the same should be done with this stream.
    _onDestroy?.cancel();
    _onUrlChanged?.cancel();
    _onStateChanged?.cancel();

    flutterWebviewPlugin.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var url = authService.getLoginUrl().toString();
    print("URL $url");
    return new WebviewScaffold(
      url: url.toString(),
      appBar: new AppBar(
        title: new Text("Login to Instagram"),
      ),
      clearCache: true,
      clearCookies: true,
      withJavascript: true,
      withLocalStorage: true,
    );
  }
}
