import 'package:flutter/material.dart';

import 'package:pastdate/screens/loading_screen.dart';
import 'package:pastdate/screens/login_screen.dart';
import 'package:pastdate/screens/home_screen.dart';
import 'package:pastdate/state_container.dart';


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("MyApp build");

    return MaterialApp(
      title: "app title",
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.purple,
        accentColor: Colors.amber,
      ),
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => new LoadingScreen(),
        '/login': (BuildContext context) => new LoginPage(),
//        '/logout': (BuildContext context) => new LogoutPage(),
        '/home': (BuildContext context) => new HomeScreen(),
//        '/database': (BuildContext context) => new TestDatabase(),
      },
    );
  }
}