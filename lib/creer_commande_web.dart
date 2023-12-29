import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'models/appartement.dart';
import 'models/commande.dart';
import 'models/detailAppartement.dart';
import 'models/residence.dart';

class CombinedSelectionDetailsPage extends StatefulWidget {
  final String entrepriseId;
  final Residence residence;

  CombinedSelectionDetailsPage({required this.entrepriseId, required this.residence});

  @override
  _CombinedSelectionDetailsPageState createState() => _CombinedSelectionDetailsPageState();
}

class _CombinedSelectionDetailsPageState extends State<CombinedSelectionDetailsPage> {
  DateTime? selectedDate;
  Map<String, bool> selectedAppartements = {};
  Map<String, DetailsAppartement> appartementDetails = {};
  List<Appartement> appartements = [];
  bool isLoading = true;

  // Déclaration de la variable noteControllers
  Map<String, TextEditingController> noteControllers = {};

  @override
  void initState() {
    super.initState();
    _loadAppartements();
  }

  void _loadAppartements() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('appartements')
          .where('residenceId', isEqualTo: widget.residence.id)
          .get();

      List<Appartement> loadedAppartements = querySnapshot.docs
          .map((doc) => Appartement.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      Map<String, bool> loadedSelectedAppartements = {};
      Map<String, DetailsAppartement> loadedAppartementDetails = {};
      Map<String, TextEditingController> loadedNoteControllers = {};

      for (var appart in loadedAppartements) {
        loadedSelectedAppartements[appart.id] = false;
        loadedAppartementDetails[appart.id] = DetailsAppartement();
        loadedNoteControllers[appart.id] = TextEditingController(text: loadedAppartementDetails[appart.id]?.note);
      }

      setState(() {
        appartements = loadedAppartements;
        selectedAppartements = loadedSelectedAppartements;
        appartementDetails = loadedAppartementDetails;
        noteControllers = loadedNoteControllers;
        isLoading = false;
      });
    } catch (error) {
      print('Erreur lors du chargement des appartements: $error');
      setState(() {
        isLoading = false;
      });
    }
  }
  @override
  void dispose() {
    // S'assurer de disposer les TextEditingController pour éviter les fuites de mémoire
    for (var controller in noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }


  Future<void> _enregistrerCommande() async {
    List<Appartement> appartementsSelectionnes = appartements.where((appart) => selectedAppartements[appart.id] ?? false).toList();
    if (appartementsSelectionnes.isEmpty) {
      // Gérer le cas où aucun appartement n'est sélectionné
      return;
    }

    // Créer une instance de commande
    Commande nouvelleCommande = Commande(
      entrepriseId: widget.entrepriseId,
      nomResidence: widget.residence.nom,
      residenceId: widget.residence.id,
      dateCommande: DateTime.now(),
      appartements: appartementsSelectionnes,
      detailsAppartements: appartementDetails, id: '', equipes: [], validation: {},
      // Ajoutez d'autres champs si nécessaire
    );

    try {
      // Enregistrer la nouvelle commande dans Firestore
      await FirebaseFirestore.instance.collection('commandes').add(nouvelleCommande.toMap());
      // Afficher un message de succès ou naviguer vers une autre page
    } catch (e) {
      // Gérer les erreurs de l'enregistrement
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélection et Détails des Appartements'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: const <DataColumn>[
              DataColumn(label: Text('Appartement')),
              DataColumn(label: Text('Prioritaire')),
              DataColumn(label: Text('Note')),
              DataColumn(label: Text('Type de Ménage')),
            ],
            rows: appartements.map<DataRow>((appart) {
              final details = appartementDetails[appart.id] ??= DetailsAppartement();
              final noteController = noteControllers[appart.id] ??= TextEditingController(text: details.note);

              return DataRow(
                cells: <DataCell>[
                  DataCell(Text(appart.numero)),
                  DataCell(Checkbox(
                    value: details.prioritaire,
                    onChanged: (bool? value) {
                      setState(() {
                        details.prioritaire = value!;
                      });
                    },
                  )),
                  DataCell(Container(
                    width: 200,
                    child: TextField(
                      style: TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Entrez une note'),
                      controller: noteController,
                      onSubmitted: (value) {
                        details.note = value;
                      },
                    ),
                  )),
                  DataCell(DropdownButton<String>(
                    value: details.typeMenage,
                    onChanged: (String? newValue) {
                      setState(() {
                        details.typeMenage = newValue!;
                      });
                    },
                    items: <String>['Ménage', 'Recouche', 'Dégraissage', 'Fermeture']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enregistrerCommande,
        child: Icon(Icons.check),
        backgroundColor: Colors.green,
        tooltip: 'Finaliser la commande',
      ),
    );
  }
}

class DetailsView extends StatelessWidget {
  final Appartement appartement;

  DetailsView({required this.appartement});

  @override
  Widget build(BuildContext context) {
    // Ajoutez ici les détails de l'appartement sélectionné
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Appartement ${appartement.numero}', style: Theme.of(context).textTheme.headline6),
          // Complétez avec d'autres détails de l'appartement
        ],
      ),
    );
  }
}
