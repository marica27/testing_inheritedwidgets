
//import 'package:pastdate/services/instagramapi.dart';
//import 'package:pastdate/services/database.dart';

import 'package:flutter/material.dart';
import 'state_container.dart';
import 'app.dart';

void main() {
  print("main");

  runApp(AppStateContainer(
    child: MyApp(),
  ));
}
