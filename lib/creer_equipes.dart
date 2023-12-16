import 'package:flutter/material.dart';

import 'models/appartement.dart';
import 'models/equipes.dart';



class CreerEquipePage extends StatefulWidget {
  final List<Appartement>? tousLesAppartements;

  CreerEquipePage({this.tousLesAppartements});

  @override
  _CreerEquipePageState createState() => _CreerEquipePageState();
}

class _CreerEquipePageState extends State<CreerEquipePage> {
  List<Equipe> equipes = [];

  @override
  void initState() {
    super.initState();
    equipes.add(Equipe(nom: 'Équipe 1', appartements: [], appartementIds: []));
  }

  void _ajouterEquipe() {
    setState(() {
      equipes.add(Equipe(nom: 'Équipe ${equipes.length + 1}', appartements: [], appartementIds: []));
    });
  }

  void _confirmerSuppressionEquipe(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer cette équipe ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Supprimer'),
              onPressed: () {
                setState(() {
                  equipes.removeAt(index);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _afficherDetailsEquipe(Equipe equipe) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sélectionnez les appartements pour ${equipe.nom}"),
          content: SingleChildScrollView(
            child: ListBody(
              children: _buildAppartementList(equipe),
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
              child: Text('Enregistrer'),
              onPressed: () {
                setState(() {});
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildAppartementList(Equipe equipe) {
    List<Widget> listItems = [];

    widget.tousLesAppartements?.forEach((appartement) {
      bool estSelectionne = equipe.appartementIds.contains(appartement.id);
      bool estDejaPris = estAppartementDejaPris(appartement.id, equipe);

      listItems.add(ListTile(
        title: Text(appartement.numero),
        leading: Checkbox(
          value: estSelectionne,
          onChanged: estDejaPris ? null : (bool? value) {
            setState(() {
              if (value == true && !estDejaPris) {
                equipe.appartementIds.add(appartement.id);
              } else if (value == false) {
                equipe.appartementIds.removeWhere((id) => id == appartement.id);
              }
            });
          },
        ),
      ));
    });

    return listItems;
  }

  bool estAppartementDejaPris(String appartementId, Equipe equipeActuelle) {
    for (var equipe in equipes) {
      if (equipe != equipeActuelle && equipe.appartementIds.contains(appartementId)) {
        return true;
      }
    }
    return false;
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: _ajouterEquipe,
              child: Text('Ajouter une nouvelle équipe'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: equipes.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(equipes[index].nom),
                      onTap: () => _afficherDetailsEquipe(equipes[index]),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _confirmerSuppressionEquipe(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}