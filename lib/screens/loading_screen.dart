import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:pastdate/state_container.dart';
import 'package:pastdate/models.dart';

class LoadingScreen extends StatefulWidget {
  @override
  LoadingScreenState createState() => new LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    print("LoadingScreen builds");

    var container = AppStateContainer.of(context);
    print("container $container");
    var appState = container.state;

    if (!appState.isLoading && appState.user == null) {
      print("LoadingScreen calls 'login'");
      Future.delayed(
          Duration(milliseconds: 1),
              () => Navigator.of(context).pushNamedAndRemoveUntil(
              "/login", (Route<dynamic> route) => false));
    } else if (!appState.isLoading) {
      print("LoadingScreen calls 'home'");
      Future.delayed(
          Duration(milliseconds: 1),
              () => Navigator.of(context).pushNamedAndRemoveUntil(
              "/home", (Route<dynamic> route) => false));
    }

    return new Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(color: Colors.cyan[50]),
            ),
            Center(child: CircularProgressIndicator()),
          ],
        ));
  }
}
