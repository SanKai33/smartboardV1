import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/personnel.dart';

class ParametreCompteAgent extends StatefulWidget {
  final String agentId;

  ParametreCompteAgent({required this.agentId});

  @override
  _ParametreCompteAgentState createState() => _ParametreCompteAgentState();
}

class _ParametreCompteAgentState extends State<ParametreCompteAgent> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }

  void _loadAgentData() async {
    setState(() => _isLoading = true);
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('personnel').doc(widget.agentId).get();
    Personnel personnel = Personnel.fromFirestore(snapshot);
    _nomController.text = personnel.nom;
    _prenomController.text = personnel.prenom;
    _emailController.text = personnel.email;
    _telephoneController.text = personnel.telephone;
    setState(() => _isLoading = false);
  }

  void _updateAgentDetails() async {
    setState(() => _isLoading = true);
    Map<String, dynamic> updatedData = {
      'nom': _nomController.text,
      'prenom': _prenomController.text,
      'email': _emailController.text,
      'telephone': _telephoneController.text
    };
    await FirebaseFirestore.instance.collection('personnel').doc(widget.agentId).update(updatedData);
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
                    await FirebaseFirestore.instance.collection('personnel').doc(widget.agentId).update({'password': passwordNewController.text});

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
        title: Text('Paramètres du Compte Agent'),
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
              onPressed: _updateAgentDetails,
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