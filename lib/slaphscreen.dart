import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'choix_du_login.dart';
import 'main_screen.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      _autoLogin();
    });
  }

  void _autoLogin() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        _navigateToMainScreen();
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: "email@entreprise.com",
          password: "motDePasse",
        );

        if (userCredential.user?.uid == "7cYXkVddxWXziiTgENtmiy7qX9Q2") {
          _navigateToMainScreen();
        } else {
          _navigateToLogin();
        }
      }
    } catch (e) {
      print("Erreur de connexion: $e");
      _navigateToLogin();
    }
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainScreen(entrepriseId: '7cYXkVddxWXziiTgENtmiy7qX9Q2', agentId: '')),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChoiceLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/icon.png', // Votre logo
                  width: constraints.maxWidth * 0.3, // Ajuste la largeur de l'image en fonction de la taille de l'écran
                  height: constraints.maxWidth * 0.3, // Ajuste la hauteur de l'image en fonction de la taille de l'écran
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(), // Un indicateur de chargement
                SizedBox(height: 20),
                Text("Chargement...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}