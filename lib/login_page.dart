import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartboard/registrer_page.dart';
import 'main_screen.dart'; // Importez votre écran principal

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Récupération de l'ID d'entreprise associé à l'utilisateur
      String userId = userCredential.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      // Convertir les données en Map pour un accès facile
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String entrepriseId = userData['entrepriseId']; // Utilisez le cast pour accéder aux données

      // Vérification de l'existence de l'entreprise
      DocumentSnapshot entrepriseDoc = await FirebaseFirestore.instance.collection('entreprise').doc(entrepriseId).get();
      if (!entrepriseDoc.exists) {
        throw Exception("Entreprise non trouvée.");
      }

      // Redirection vers l'écran principal avec l'entrepriseId
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen(entrepriseId: entrepriseId)),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'Aucun utilisateur trouvé pour cet email.';
      } else if (e.code == 'wrong-password') {
        message = 'Mauvais mot de passe fourni pour cet utilisateur.';
      } else {
        message = 'Une erreur est survenue. Veuillez réessayer plus tard.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _login(context),
                  child: Text('Connexion'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => RegisterPage()), // Assurez-vous que cette page existe dans votre projet
                    );
                  },
                  child: Text('Créer un compte'),
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).primaryColor,
                    onPrimary: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

