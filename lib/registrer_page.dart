import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'main_screen.dart';
import 'models/entreprise.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomEntrepriseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adminPasswordController = TextEditingController(); // Contrôleur pour le mot de passe administrateur
  bool _isLoading = false;

  final String _adminPassword = "0703"; // Mot de passe administrateur

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomEntrepriseController.dispose();
    _telephoneController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _adminPasswordController.text == _adminPassword) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        String userId = userCredential.user!.uid;

        Entreprise entreprise = Entreprise(
          id: userId,
          nom: _nomEntrepriseController.text.trim(),
          email: _emailController.text.trim(),
          telephone: _telephoneController.text.trim(),
        );

        await FirebaseFirestore.instance.collection('entreprise').doc(userId).set(entreprise.toMap());

        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => MainScreen(agentId: userId, entrepriseId: userId),
        ));
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(e.message ?? "Une erreur s'est produite.");
      }
    } else {
      _showErrorDialog("Mot de passe administrateur incorrect.");
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
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un compte Entreprise'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nomEntrepriseController,
                decoration: InputDecoration(labelText: 'Nom de l\'entreprise'),
                validator: (value) => value != null && value.isEmpty ? "Entrez le nom de l'entreprise" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Adresse e-mail'),
                validator: (value) => value != null && !value.contains('@') ? "Entrez une adresse e-mail valide" : null,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (value) => value != null && value.length < 6 ? "Le mot de passe doit contenir au moins 6 caractères" : null,
              ),
              TextFormField(
                controller: _telephoneController,
                decoration: InputDecoration(labelText: 'Téléphone (facultatif)'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _adminPasswordController,
                decoration: InputDecoration(labelText: 'Mot de passe administrateur'),
                obscureText: true,
                validator: (value) => value != _adminPassword ? "Mot de passe administrateur invalide" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Créer un compte'),
                onPressed: _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}