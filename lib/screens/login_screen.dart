import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:pastdate/main.dart';
import 'package:pastdate/state_container.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("LoginPage builds ${AppStateContainer.of(context).state}");

    var container = AppStateContainer.of(context);
    var appState = container.state;

    if (!appState.isLoading && appState.isUserLoggedIn()) {
      Future.delayed(
          Duration(milliseconds: 1),
              () => Navigator.of(context).pushNamedAndRemoveUntil(
              "/home", (Route<dynamic> route) => false));
    }
    return new Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("do login");
          AppStateContainer.of(context).login();
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text("Login..."),
      ),
      body: Center(
        child: new RaisedButton(
          padding: const EdgeInsets.all(8.0),
          textColor: Colors.white,
          color: Colors.blue,
          onPressed: doLogin,
          child: new Text("login"),
        ),
      ),
    );
  }

  void doLogin() {
    print("do login");
//    AppStateContainer.of(context).login();
  }
}
