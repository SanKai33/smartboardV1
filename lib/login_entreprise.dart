import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/main_screen.dart';

import 'models/entreprise.dart';

class EntrepriseLoginPage extends StatefulWidget {
  @override
  _EntrepriseLoginPageState createState() => _EntrepriseLoginPageState();
}

class _EntrepriseLoginPageState extends State<EntrepriseLoginPage> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Instance de Firestore
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion Entreprise'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : SingleChildScrollView( // Ajout d'un SingleChildScrollView pour gérer le débordement
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Image.asset('assets/images/icon.png', height: 120), // Ajout de l'image du logo
              SizedBox(height: 20),
              TextField(
                controller: _companyNameController,
                decoration: InputDecoration(
                  labelText: 'Nom de l\'entreprise',
                  hintText: 'Entrez le nom de votre entreprise',
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  hintText: 'Entrez votre mot de passe',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.black, // Couleur du texte
                    minimumSize: Size(double.infinity, 50) // Largeur complète et hauteur fixe
                ),
                onPressed: _login,
                child: Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    String companyName = _companyNameController.text.trim();

    try {
      // Recherche de l'entreprise par son nom
      QuerySnapshot querySnapshot = await _firestore.collection('entreprises')
          .where('nom', isEqualTo: companyName)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'company-not-found',
          message: 'Aucune entreprise trouvée avec ce nom',
        );
      }

      DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
      Entreprise entreprise = Entreprise.fromMap(documentSnapshot.data() as Map<String, dynamic>, documentSnapshot.id);

      // Passage de la vérification du mot de passe pour démonstration
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => MainScreen(entrepriseId: entreprise.id, agentId: '',),
      ));

    } catch (e) {
      _showErrorDialog(e is FirebaseAuthException ? e.message! : "Une erreur est survenue lors de la connexion.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Ok'),
            onPressed: () {
              Navigator.of(ctx). pop();
            },
          ),
        ],
      ),
    );
  }
}