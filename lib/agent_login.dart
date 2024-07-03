import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'appAgent/main_screen_agent.dart';
import 'models/personnel.dart';


class AgentLoginPage extends StatefulWidget {
  @override
  _AgentLoginPageState createState() => _AgentLoginPageState();
}

class _AgentLoginPageState extends State<AgentLoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _identifiant = '';
  String _password = '';

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        print("Tentative de connexion avec l'identifiant: $_identifiant");

        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('auth')
            .where('identifiant', isEqualTo: _identifiant)
            .get();

        if (querySnapshot.docs.isEmpty) {
          _showErrorDialog('Identifiant incorrect');
          return;
        }

        var userDoc = querySnapshot.docs.first;
        var userData = userDoc.data() as Map<String, dynamic>;
        print("Utilisateur trouvé: $userData");

        if (userData['password'] != _password) {
          _showErrorDialog('Mot de passe incorrect');
          return;
        }

        // Utiliser l'identifiant du document auth pour récupérer le document personnel correspondant
        QuerySnapshot personnelQuerySnapshot = await FirebaseFirestore.instance
            .collection('personnel')
            .where('identifiant', isEqualTo: _identifiant)
            .get();

        if (personnelQuerySnapshot.docs.isEmpty) {
          _showErrorDialog('Utilisateur introuvable dans la collection personnel');
          return;
        }

        var personnelDoc = personnelQuerySnapshot.docs.first;
        Personnel personnel = Personnel.fromFirestore(personnelDoc);
        print("Données du personnel: ${personnel.toMap()}");

        // Redirection vers MainScreenAgent
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => MainScreenAgent(entrepriseId: personnel.entrepriseId, agentId: personnel.id, clientId: '',),
        ));
      } catch (e) {
        _showErrorDialog('Erreur de connexion');
        print('Erreur lors de la connexion: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erreur'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
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
        title: Text('Connexion Agent'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextFormField(
                  decoration: InputDecoration(labelText: 'Identifiant'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre identifiant';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _identifiant = value!;
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextFormField(
                  decoration: InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value!;
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _login,
                child: Text('Connexion'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


