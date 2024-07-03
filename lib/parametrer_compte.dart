import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartboard/slaphscreen.dart';

import 'models/entreprise.dart';

class ParametreCompte extends StatefulWidget {
  final String entrepriseId;

  ParametreCompte({required this.entrepriseId});

  @override
  _ParametreCompteState createState() => _ParametreCompteState();
}

class _ParametreCompteState extends State<ParametreCompte> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEntrepriseData();
  }

  void _loadEntrepriseData() async {
    setState(() => _isLoading = true);
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('entreprises').doc(widget.entrepriseId).get();
    Entreprise entreprise = Entreprise.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
    _nomController.text = entreprise.nom;
    _emailController.text = entreprise.email ?? '';
    _telephoneController.text = entreprise.telephone ?? '';
    _imageUrl = entreprise.imageUrl;
    setState(() => _isLoading = false);
  }

  void _updateEntrepriseDetails() async {
    setState(() => _isLoading = true);
    Map<String, dynamic> updatedData = {
      'nom': _nomController.text,
      'email': _emailController.text,
      'telephone': _telephoneController.text,
      'imageUrl': _imageUrl,
    };
    await FirebaseFirestore.instance.collection('entreprises').doc(widget.entrepriseId).update(updatedData);
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Informations mises à jour avec succès.')));
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String fileName = 'profile_images/${widget.entrepriseId}.png';
      UploadTask uploadTask = FirebaseStorage.instance.ref().child(fileName).putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      setState(() {
        _imageUrl = downloadUrl;
      });
    }
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

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SplashScreen()), // Redirige vers la page SplashScreen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres du Compte'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                      child: _imageUrl == null ? Icon(Icons.account_circle, size: 50) : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _nomController,
                  decoration: InputDecoration(labelText: 'Nom de l\'entreprise'),
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
                  onPressed: _updateEntrepriseDetails,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  ),
                  child: Text('Mettre à jour les informations'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  ),
                  child: Text('Changer le mot de passe'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  ),
                  child: Text('Déconnexion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}