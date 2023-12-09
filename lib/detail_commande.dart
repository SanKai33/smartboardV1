import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartboard/main_screen.dart';
import 'models/appartement.dart';
import 'models/commande.dart';
import 'models/residence.dart';


class CommandeDetailsPage extends StatefulWidget {
  final List<Appartement> appartementsSelectionnes;
  final DateTime dateCommande;
  final String entrepriseId;
  final Residence residence; // Ajoutez ceci si vous avez besoin de la résidence

  CommandeDetailsPage({
    Key? key,
    required this.appartementsSelectionnes,
    required this.dateCommande,
    required this.entrepriseId,
    required this.residence, // N'oubliez pas d'ajouter ceci dans le constructeur
  }) : super(key: key);

  @override
  _CommandeDetailsPageState createState() => _CommandeDetailsPageState();
}

class _CommandeDetailsPageState extends State<CommandeDetailsPage> {
  Map<String, Map<String, dynamic>> appartementDetails = {};

  @override
  void initState() {
    super.initState();
    for (var appartement in widget.appartementsSelectionnes) {
      appartementDetails[appartement.numero] = {
        'prioritaire': false,
        'note': '',
        'typeMenage': 'Ménage'
      };
    }
  }
  void _showAppartementDialog(Appartement appartement) {
    var details = appartementDetails[appartement.numero];
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
                    value: details?['prioritaire'],
                    onChanged: (bool? value) {
                      setState(() {
                        details?['prioritaire'] = value;
                      });
                    },
                  ),
                  TextFormField(
                    initialValue: details?['note'],
                    decoration: const InputDecoration(labelText: 'Note'),
                    onChanged: (value) {
                      details?['note'] = value;
                    },
                  ),
                  DropdownButton<String>(
                    value: details?['typeMenage'],
                    onChanged: (String? newValue) {
                      setState(() {
                        details?['typeMenage'] = newValue;
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
                  appartementDetails[appartement.numero] = details!;
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



    Map<String, dynamic> appartementDetailsFormatted = {};
    for (var appartement in widget.appartementsSelectionnes) {
      appartementDetailsFormatted[appartement.id] = {
        'prioritaire': appartement.prioritaire,
        'note': appartement.note,
        'typeMenage': appartement.typeMenage,
      };
    }

    // Construisez la commande
    Commande commande = Commande(
      id: FirebaseFirestore.instance.collection('commandes').doc().id,
      nomResidence: widget.residence.nom,
      dateCommande: widget.dateCommande,
      appartements: widget.appartementsSelectionnes,
      detailsAppartements: {}, entrepriseId: '', // Remplacez ceci par votre logique de détail
    );
    // Enregistrez la commande dans la collection 'commandes'
    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('commandes').add(commande.toMap());
      // Vérifiez si le document a été créé avec succès
      if (docRef.id.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Commande enregistrée avec succès avec ID: ${docRef.id}')));
        // Naviguez vers la page principale ou effectuez d'autres actions
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'enregistrement de la commande: ${e.toString()}')));
    }



    // Puis naviguer vers la page principale
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainScreen(entrepriseId: widget.entrepriseId)),
          (Route<dynamic> route) => false,
    );
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
          final details = appartementDetails[appartement.numero]!;
          return Card(
            child: ListTile(
              title: Text('Appartement ${appartement.numero}'),
              subtitle: Text('${details['typeMenage']}${details['prioritaire'] ? " (Prioritaire)" : ""}\\nNote: ${details['note']}'),
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