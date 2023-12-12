import 'package:flutter/material.dart';

class CreerEquipePage extends StatefulWidget {
  @override
  _CreerEquipePageState createState() => _CreerEquipePageState();
}

class _CreerEquipePageState extends State<CreerEquipePage> {
  final TextEditingController _nomEquipeController = TextEditingController();
  final TextEditingController _descriptionEquipeController = TextEditingController();

  void _creerEquipe() {
    // TODO: Implémentez la logique pour créer une équipe
    // Utilisez les données des contrôleurs pour enregistrer l'équipe
    print('Nom de l\'équipe: ${_nomEquipeController.text}');
    print('Description de l\'équipe: ${_descriptionEquipeController.text}');

    // Naviguer vers une autre page ou afficher un message de succès
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer une Équipe'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _nomEquipeController,
              decoration: InputDecoration(
                labelText: 'Nom de l\'équipe',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _descriptionEquipeController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _creerEquipe,
              child: Text('Créer Équipe'),
            ),
          ],
        ),
      ),
    );
  }
}