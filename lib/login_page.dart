import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';
import 'registrer_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> _login(BuildContext context) async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar(context, "Veuillez entrer une adresse email valide.");
      return;
    }
    if (password.isEmpty) {
      _showSnackBar(context, "Veuillez entrer votre mot de passe.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Récupération de l'ID d'entreprise associé à l'utilisateur
      String userId = userCredential.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.data() == null) {
        throw Exception("Les données de l'utilisateur ne sont pas disponibles.");
      }

      // Convertir les données en Map pour un accès facile
      Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;
      String entrepriseId = userData['entrepriseId'];

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
      _showSnackBar(context, "Erreur Firebase: ${e.message}");
    } catch (e) {
      _showSnackBar(context, e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 50),
            Image.asset('assets/images/icon.png', width: 100, height: 100),
            SizedBox(height: 50),
            Padding(
              padding: EdgeInsets.all(16.0),
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
                    child: Text(isLoading ? 'Connexion en cours...' : 'Connexion'),
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
                        MaterialPageRoute(builder: (context) => RegisterPage()),
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
          ],
        ),
      ),
    );
  }
}
