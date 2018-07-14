import "package:flutter/material.dart";
import 'package:pastdate/state_container.dart';


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("HomePage builds");
    var container = AppStateContainer.of(context);
    var appState = container.state;

    return Scaffold(
      appBar: AppBar(
        title: Text("Hello, ${appState.user.username}"),
      ),
      body: new Center(child: Text(
        "${appState.user.username}",
        style: TextStyle(fontSize: 36.0),
      )),
    );
  }
}