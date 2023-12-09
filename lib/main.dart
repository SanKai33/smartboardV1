
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:smartboard/slaphscreen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Assurez-vous que c'est la première ligne dans main
  await Firebase.initializeApp(); // Attendez que Firebase soit initialisé avant de lancer l'application
  runApp(MaterialApp(home: SplashScreen()));

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
      //home: LoginPage(), // La page de connexion est le premier écran affiché

    );
  }
}





