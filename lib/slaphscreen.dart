import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smartboard/login_page.dart';
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
      _navigateToMainScreen();
    });
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage())
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
