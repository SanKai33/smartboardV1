

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:smartboard/slaphscreen.dart';
import 'firebase_options.dart'; // Assurez-vous que ce fichier est correctement généré

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Écouter les changements de l'état d'authentification avant de lancer l'application
  await FirebaseAuth.instance.authStateChanges().first;

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
      home: SplashScreen(), // La page SplashScreen est le premier écran affiché
    );
  }
}





