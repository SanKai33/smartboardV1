import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models/entreprise.dart';


class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  String? _email;
  String? _phoneNumber;
  Entreprise? _selectedEntreprise;
  List<Entreprise> _entreprises = [];

  @override
  void initState() {
    super.initState();
    _loadEntreprises();
  }

  void _loadEntreprises() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance.collection('entreprises').get();
      List<Entreprise> tempEntreprises = querySnapshot.docs.map((doc) {
        return Entreprise.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      setState(() {
        _entreprises = tempEntreprises;
      });
    } catch (e) {
      print('Erreur lors du chargement des entreprises: $e');
    }
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print('Sign Up with: First name: $_firstName, Last name: $_lastName, Email: $_email, Phone: $_phoneNumber, Entreprise: ${_selectedEntreprise?.nom}');
      // Ajoutez ici votre logique pour enregistrer ces informations dans votre base de données
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription Agent'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 30),
                Image.asset('assets/images/logo.png', height: 120),  // Vérifiez que cette image est dans le dossier assets/images
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Nom'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _lastName = value!;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Prénom'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre prénom';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _firstName = value!;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Email (Facultatif)'),
                    onSaved: (value) {
                      _email = value;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Numéro de téléphone (Facultatif)'),
                    onSaved: (value) {
                      _phoneNumber = value;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: DropdownButtonFormField<Entreprise>(
                    decoration: InputDecoration(labelText: 'Choisir une entreprise'),
                    value: _selectedEntreprise,
                    onChanged: (Entreprise? newValue) {
                      setState(() {
                        _selectedEntreprise = newValue;
                      });
                    },
                    items: _entreprises.map<DropdownMenuItem<Entreprise>>((Entreprise entreprise) {
                      return DropdownMenuItem<Entreprise>(
                        value: entreprise,
                        child: Text(entreprise.nom),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Veuillez sélectionner une entreprise' : null,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 50) // Bouton étendu sur toute la largeur
                  ),
                  onPressed: _signUp,
                  child: Text('Inscription'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}