import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/entreprise.dart'; // Assurez-vous d'importer le modèle Entreprise
import 'main_screen.dart'; // Page d'accueil ou de redirection après l'enregistrement

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  String selectedType = 'entreprise'; // 'entreprise' ou 'personnel'
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _registerEntreprise() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      Entreprise nouvelleEntreprise = Entreprise(
        id: userCredential.user!.uid,
        nom: nomController.text,
        email: emailController.text,
      );

      await _firestore.collection('entreprise').doc(nouvelleEntreprise.id).set(nouvelleEntreprise.toMap());

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen(entrepriseId: nouvelleEntreprise.id)));
    } on FirebaseAuthException catch (e) {
      // Gérer les erreurs d'authentification ici
    }
  }

  // Ici, vous pouvez ajouter une fonction similaire pour enregistrer le personnel de nettoyage

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enregistrer un compte'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: selectedType,
              onChanged: (newValue) => setState(() => selectedType = newValue!),
              items: ['entreprise', 'personnel']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            if (selectedType == 'entreprise')
              TextField(
                controller: nomController,
                decoration: InputDecoration(labelText: 'Nom de l\'entreprise'),
              ),
            if (selectedType == 'personnel') ...[
              TextField(
                controller: nomController,
                decoration: InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: prenomController,
                decoration: InputDecoration(labelText: 'Prénom'),
              ),
            ],
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedType == 'entreprise' ? _registerEntreprise : null, // Connectez la fonction appropriée ici
              child: Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}