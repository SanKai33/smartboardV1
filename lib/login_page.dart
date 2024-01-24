import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartboard/registrer_page.dart';

import 'main_screen.dart';
import 'models/entreprise.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Vérifier si l'utilisateur est une entreprise
      DocumentSnapshot entrepriseDoc = await FirebaseFirestore.instance.collection('entreprises').doc(userCredential.user!.uid).get();
      if (entrepriseDoc.exists) {
        // Rediriger vers la page MainScreen avec les données de l'entreprise
        Entreprise entreprise = Entreprise.fromMap(entrepriseDoc.data() as Map<String, dynamic>, userCredential.user!.uid);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => MainScreen (entrepriseId: '', agentId: '',),
        ));
      } else {
        _showError("L'utilisateur n'est pas enregistré en tant qu'entreprise.");
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Erreur lors de la connexion");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connexion Entreprise')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _signIn,
                child: Text('Se connecter'),
              ),
              TextButton(
                onPressed: () {
                  // Naviguer vers la page d'inscription
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => RegisterPage()));
                },
                child: Text('Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
