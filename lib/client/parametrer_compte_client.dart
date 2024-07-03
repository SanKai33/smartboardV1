import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/client.dart';

class ParametreCompteClient extends StatefulWidget {
  final String clientId;

  ParametreCompteClient({required this.clientId});

  @override
  _ParametreCompteClientState createState() => _ParametreCompteClientState();
}

class _ParametreCompteClientState extends State<ParametreCompteClient> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  void _loadClientData() async {
    setState(() => _isLoading = true);
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).get();
    Client client = Client.fromFirestore(snapshot);
    _nomController.text = client.nom;
    _prenomController.text = client.prenom;
    _emailController.text = client.email;
    _telephoneController.text = client.telephone;
    setState(() => _isLoading = false);
  }

  void _updateClientDetails() async {
    setState(() => _isLoading = true);
    Map<String, dynamic> updatedData = {
      'nom': _nomController.text,
      'prenom': _prenomController.text,
      'email': _emailController.text,
      'telephone': _telephoneController.text
    };
    await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).update(updatedData);
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Informations mises à jour avec succès.')));
  }

  void _changePassword() async {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController passwordNewController = TextEditingController();
        TextEditingController passwordConfirmController = TextEditingController();
        return AlertDialog(
          title: Text('Changer le mot de passe'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: passwordNewController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                  ),
                ),
                TextField(
                  controller: passwordConfirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Changer'),
              onPressed: () async {
                if (passwordNewController.text == passwordConfirmController.text) {
                  try {
                    User? user = FirebaseAuth.instance.currentUser;
                    await user?.updatePassword(passwordNewController.text);

                    // Mettre à jour le mot de passe dans Firestore
                    await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).update({'password': passwordNewController.text});

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mot de passe mis à jour avec succès.')));
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la mise à jour du mot de passe.')));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Les mots de passe ne correspondent pas.')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres du Compte Client'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nomController,
              decoration: InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: _prenomController,
              decoration: InputDecoration(labelText: 'Prénom'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _telephoneController,
              decoration: InputDecoration(labelText: 'Téléphone'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateClientDetails,
              child: Text('Mettre à jour les informations'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Changer le mot de passe'),
            ),
          ],
        ),
      ),
    );
  }
}