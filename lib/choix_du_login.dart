import 'package:flutter/material.dart';
import 'package:smartboard/client/client_login_page.dart';

import 'administrateur_gestion.dart';
import 'agent_login.dart';
import 'login_entreprise.dart';

class ChoiceLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Couleur de fond originale
      appBar: AppBar(
        title: Text(
          'Connexion',  // Titre modifié
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/icon.png'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Ajout de padding horizontal
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            LoginCard(
              title: 'Entreprise',
              icon: Icons.business,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EntrepriseLoginPage()));
              },
              color: Color(0xFF007BFF), // Couleur bleue pour Entreprise
            ),
            SizedBox(height: 20),
            LoginCard(
              title: 'Client / Réception',
              icon: Icons.people,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ClientLoginPage()));
              },
              color: Color(0xFF28A745), // Couleur verte pour Client / Réception
            ),
            SizedBox(height: 20),
            LoginCard(
              title: 'Agent',
              icon: Icons.person,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AgentLoginPage()));
              },
              color: Color(0xFFFFC107), // Couleur jaune pour Agent
            ),
            SizedBox(height: 40),
            TextButton(
              onPressed: () {
                _showAdminLoginDialog(context);
              },
              child: Text(
                'Connexion Administrateur',
                style: TextStyle(color: Colors.grey[600], decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
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
            ElevatedButton(
              child: Text('Valider'),
              onPressed: () {
                if (_passwordController.text == '2233') {
                  Navigator.of(context).pop();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AdministrateurGestion()));
                } else {
                  Navigator.of(context).pop();
                  _showErrorDialog(context);
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black,
              ),
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

class LoginCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const LoginCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      color: color, // Application de la couleur choisie
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 80,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}