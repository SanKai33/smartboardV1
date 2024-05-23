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
        // Si l'utilisateur est déjà connecté
        _navigateToMainScreen();
      } else {
        // Connectez-vous avec les identifiants codés en dur
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: "email@entreprise.com", // Remplacez par l'email de l'entreprise
          password: "motDePasse", // Remplacez par le mot de passe
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
        MaterialPageRoute(builder: (_) => MainScreen(entrepriseId: '7cYXkVddxWXziiTgENtmiy7qX9Q2', agentId: '')) // Remplacez par votre écran principal
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChoiceLoginPage())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/images/icon.png'), // Votre logo
            SizedBox(height: 20),
            CircularProgressIndicator(), // Un indicateur de chargement
            SizedBox(height: 20),
            Text("Chargement...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}