import 'package:flutter/material.dart';

import 'administrateur_gestion.dart';
import 'agent_login.dart';

import 'login_entreprise.dart';

class ChoiceLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Choix du Login'),
        backgroundColor: Colors.white,
        leading: Image.asset('assets/images/icon.png'), // Ajout du logo ici
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                LoginButton(title: 'Entreprise', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EntrepriseLoginPage()));
                }),
                SizedBox(height: 20),
                LoginButton(title: 'Agent', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AgentLoginPage()));
                }),
              ],
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: LoginButton(title: 'Administrateur', onTap: () {
              _showAdminLoginDialog(context);
            }),
          ),
        ],
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController _passwordController = TextEditingController();
        return AlertDialog(
          title: Text('Mot de passe Administrateur'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Entrez le mot de passe',
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
              child: Text('Valider'),
              onPressed: () {
                if (_passwordController.text == '2233') {
                  Navigator.of(context). pop(); // Ferme le dialogue
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AdministrateurGestion()));
                } else {
                  Navigator.of(context).pop();
                  _showErrorDialog(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erreur'),
          content: Text('Mot de passe incorrect'),
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
}

class LoginButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const LoginButton({Key? key, required this.title, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.black,
        minimumSize: Size(200, 50),
      ),
      onPressed: onTap,
      child: Text(title),
    );
  }
}
