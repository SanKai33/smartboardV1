
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/main_screen.dart';

import 'package:smartboard/slaphscreen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());

 }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartBoard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(entrepriseId: '',), // La page de connexion est le premier écran affiché

    );
  }
}





