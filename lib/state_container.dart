import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import "package:instagram/instagram.dart";
import 'models.dart';

class AppStateContainer extends StatefulWidget {
  final AppState state;
  final Widget child;

  AppStateContainer({
    @required this.child,
    this.state,
  });

  // This creates a method on the AppState that's just like 'of'
  // On MediaQueries, Theme, etc
  // This is the secret to accessing your AppState all over your app
  static _AppStateContainerState of(BuildContext context) {
    print("inherited ${context.inheritFromWidgetOfExactType(_InheritedStateContainer)}");
    var obj = (context.inheritFromWidgetOfExactType(_InheritedStateContainer)
    as _InheritedStateContainer)
        .data;
    print("~~ of ~~ $obj ${obj.state}");
    return obj;
  }


  @override
  _AppStateContainerState createState() => new _AppStateContainerState();
}

class _AppStateContainerState extends State<AppStateContainer> {
  AppState state;

  @override
  void initState() {
    super.initState();
    print("AppStateContainerState init appState=${widget.state}");
    if (widget.state != null) {
      state = widget.state;
    } else {
      state = new AppState.loading();
      initUser();
    }
  }

  Future initUser() async {
    print("init user");
    Timer(
        Duration(seconds: 3),
            () => setState(() {
          state.isLoading = false;
        }));
  }

  login() async {
    print("login");
    setState(() {
      state.isLoading = false;
      state.user = new User(username: "marica");
    });
  }

  @override
  Widget build(BuildContext context) {
    print("AppStateContainerState builds _InheritedStateContainer appState=${state}");
    return new _InheritedStateContainer(
      data: this,
      child: widget.child,
    );
  }
}

class _InheritedStateContainer extends InheritedWidget {
  final _AppStateContainerState data;

  _InheritedStateContainer({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedStateContainer old) => true;
}
