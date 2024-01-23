import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartboard/registrer_page.dart';

import 'main_screen.dart';

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

      // Vérification si l'email appartient à un compte entreprise
      final userDoc = await FirebaseFirestore.instance.collection('entreprises').doc(userCredential.user!.uid).get();
      if (userDoc.exists) {
        // Si utilisateur est une entreprise, redirection vers la page principale de l'entreprise
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen(entrepriseId: userCredential.user!.uid, agentId: '',)));
      } else {
        _showError("Ce compte n'est pas enregistré comme entreprise.");
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
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
              ),
              SizedBox(height: 30),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _signIn,
                child: Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


