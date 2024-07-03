import 'package:flutter/material.dart';
import 'package:smartboard/client/client_login_page.dart';

import 'administrateur_gestion.dart';
import 'agent_login.dart';

import 'login_entreprise.dart';

class ChoiceLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Choix du Login',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/icon.png'),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                LoginCard(
                  title: 'Entreprise',
                  icon: Icons.business,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EntrepriseLoginPage()));
                  },
                ),
                SizedBox(height: 20),
                LoginCard(
                  title: 'Client/Reception',
                  icon: Icons.people,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ClientLoginPage()));
                  },
                ),
                SizedBox(height: 20),
                LoginCard(
                  title: 'Agent',
                  icon: Icons.person,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AgentLoginPage()));
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: LoginCard(
              title: 'Administrateur',
              icon: Icons.admin_panel_settings,
              onTap: () {
                _showAdminLoginDialog(context);
              },
              isAdmin: true, // Indicate that this is the admin button
            ),
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
  final bool isAdmin;

  const LoginCard({Key? key, required this.title, required this.icon, required this.onTap, this.isAdmin = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: isAdmin ? 150 : 250, // Make the admin button smaller
          height: isAdmin ? 50 : 100, // Make the admin button smaller
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.transparent, // Make the button transparent
            border: Border.all(color: Colors.black87), // Add a border to the button
          ),
          child: Center(
            child: ListTile(
              leading: Icon(icon, size: isAdmin ? 30 : 40, color: Colors.black87),
              title: Text(
                title,
                style: TextStyle(fontSize: isAdmin ? 14 : 20, color: Colors.black87, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}