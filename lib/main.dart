import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';


import 'app.dart';
import 'firebase_options.dart';
import 'locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );



  setupDependencies();

  await locator.allReady();

  runApp(const App());
}