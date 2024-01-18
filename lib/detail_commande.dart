import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/main_screen.dart';
import 'models/appartement.dart';
import 'models/commande.dart';
import 'models/detailAppartement.dart';
import 'models/residence.dart';

class CommandeDetailsPage extends StatefulWidget {
  final List<Appartement> appartementsSelectionnes;
  final DateTime dateCommande;
  final String entrepriseId;
  final Residence residence;

  CommandeDetailsPage({
    Key? key,
    required this.appartementsSelectionnes,
    required this.dateCommande,
    required this.entrepriseId,
    required this.residence,
  }) : super(key: key);

  @override
  _CommandeDetailsPageState createState() => _CommandeDetailsPageState();
}

class _CommandeDetailsPageState extends State<CommandeDetailsPage> {
  Map<String, DetailsAppartement> appartementDetails = {};

  @override
  void initState() {
    super.initState();
    for (var appartement in widget.appartementsSelectionnes) {
      appartementDetails[appartement.id] = DetailsAppartement();
    }
  }

  void _showAppartementDialog(Appartement appartement) {
    var details = appartementDetails[appartement.id];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails de l\'appartement ${appartement.numero}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CheckboxListTile(
                    title: const Text('Prioritaire'),
                    value: details?.prioritaire,
                    onChanged: (bool? value) {
                      setState(() {
                        details?.prioritaire = value!;
                      });
                    },
                  ),
                  TextFormField(
                    initialValue: details?.note,
                    decoration: const InputDecoration(labelText: 'Note'),
                    onChanged: (value) {
                      details?.note = value;
                    },
                  ),
                  DropdownButton<String>(
                    value: details?.typeMenage,
                    onChanged: (String? newValue) {
                      setState(() {
                        details?.typeMenage = newValue!;
                      });
                    },
                    items: <String>['Ménage', 'Recouche', 'Dégraissage', 'Fermeture']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Enregistrer'),
              onPressed: () {
                setState(() {
                  appartementDetails[appartement.id] = details!;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _finaliserCommande() async {
    Commande commande = Commande(
      id: FirebaseFirestore.instance.collection('commandes').doc().id,
      nomResidence: widget.residence.nom,
      dateCommande: widget.dateCommande,
      appartements: widget.appartementsSelectionnes,
      detailsAppartements: appartementDetails,
      entrepriseId: widget.entrepriseId,
      equipes: [],
      validation: {}, residenceId: '', ordreAppartements: {}, personnelIds: [],
    );

    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('commandes').add(commande.toMap());
      if (docRef.id.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'titre': 'Nouvelle commande',
          'message': 'Une nouvelle commande a été passée pour la résidence ${widget.residence.nom}.',
          'timestamp': FieldValue.serverTimestamp(),
          'entrepriseId': widget.entrepriseId,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Commande enregistrée avec succès avec ID: ${docRef.id}')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(entrepriseId: widget.entrepriseId)),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'enregistrement de la commande: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la Commande'),
      ),
      body: ListView.builder(
        itemCount: widget.appartementsSelectionnes.length,
        itemBuilder: (context, index) {
          final appartement = widget.appartementsSelectionnes[index];
          final details = appartementDetails[appartement.id]!;
          return Card(
            child: ListTile(
              title: Text('Appartement ${appartement.numero}'),
              subtitle: Text('${details.typeMenage}${details.prioritaire ? " (Prioritaire)" : ""}\nNote: ${details.note}'),
              onTap: () => _showAppartementDialog(appartement),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _finaliserCommande,
        child: Icon(Icons.check),
        backgroundColor: Colors.green,
      ),
    );
  }
}