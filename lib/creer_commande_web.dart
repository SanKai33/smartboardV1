import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/appartement.dart';
import 'models/commande.dart';
import 'models/detailAppartement.dart';
import 'models/residence.dart';

class CombinedSelectionDetailsPage extends StatefulWidget {
  final String entrepriseId;
  final Residence residence;
  final Commande? commandeExistante; // Ajout d'un paramètre pour la commande existante

  CombinedSelectionDetailsPage({required this.entrepriseId, required this.residence, this.commandeExistante});

  @override
  _CombinedSelectionDetailsPageState createState() => _CombinedSelectionDetailsPageState();
}

class _CombinedSelectionDetailsPageState extends State<CombinedSelectionDetailsPage> {
  DateTime? selectedDate;
  Map<String, bool> selectedAppartements = {};
  Map<String, int> ordreAppartements = {};
  Map<String, DetailsAppartement> appartementDetails = {};
  List<Appartement> appartements = [];
  bool isLoading = true;
  Map<String, TextEditingController> ordreControllers = {};

  // Déclaration de la variable noteControllers
  Map<String, TextEditingController> noteControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.commandeExistante != null) {
      // Initialiser l'état de la page avec les données de la commande existante
      _initializeWithExistingCommande(widget.commandeExistante!);
    } else {
      _loadAppartements();
    }
  }
  void _initializeWithExistingCommande(Commande commande) {

    setState(() {
      isLoading = false;
      selectedDate = commande.dateCommande;



      // Initialise les appartements sélectionnés et les détails
      selectedAppartements.clear();
      appartementDetails.clear();
      noteControllers.clear();

      for (var appartement in commande.appartements) {
        selectedAppartements[appartement.id] = true;

        if (commande.detailsAppartements.containsKey(appartement.id)) {
          var details = commande.detailsAppartements[appartement.id]!;
          appartementDetails[appartement.id] = details;

          // Créez un TextEditingController pour chaque note d'appartement
          noteControllers[appartement.id] = TextEditingController(text: details.note);
          ordreControllers[appartement.id] = TextEditingController(text: details.ordreAppartements.toString());

          // Utilisez l'ordre défini dans DetailsAppartement
          ordreAppartements[appartement.id] = details.ordreAppartements; // Changé ici
        } else {
          appartementDetails[appartement.id] = DetailsAppartement();
          noteControllers[appartement.id] = TextEditingController();

        }
      }
    });
  }


  void _loadAppartements() async {
    setState(() {
      isLoading = true;
    });

    // Remplacez cette partie par votre propre logique de chargement des données
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('appartements')
          .where('residenceId', isEqualTo: widget.residence.id)
          .get();

      var loadedAppartements = querySnapshot.docs
          .map((doc) => Appartement.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      setState(() {
        appartements = loadedAppartements;
        for (var appart in loadedAppartements) {
          selectedAppartements[appart.id] = false;
          appartementDetails[appart.id] = DetailsAppartement();
          ordreAppartements[appart.id] = 0; // Initialiser l'ordre à 0
          noteControllers[appart.id] = TextEditingController();
        }
        isLoading = false;
      });
    } catch (e) {
      // Gérer les erreurs de chargement
      print('Erreur lors du chargement des appartements: $e');
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

  void validateOrder() {
    var uniqueOrders = ordreAppartements.values.toSet();
    if (uniqueOrders.length != ordreAppartements.length) {
      throw Exception('Les ordres d\'appartements doivent être uniques.');
    }
    if (ordreAppartements.values.any((order) => order == null || order < 1)) {
      throw Exception('Les ordres d\'appartements doivent être des nombres positifs non nuls.');
    }
  }

  bool isSaving = false;
  Future<void> _enregistrerCommande() async {
    // Vérifiez si au moins un appartement est sélectionné
    if (selectedAppartements.values.every((selected) => !selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Aucun appartement sélectionné"))
      );
      return;
    }

    // Préparation des détails de chaque appartement, y compris l'ordre, la note, et l'état libre/pas libre
    var detailsWithOrder = Map<String, DetailsAppartement>.from(appartementDetails);
    for (var appartementId in detailsWithOrder.keys) {
      var details = detailsWithOrder[appartementId]!;
      var noteController = noteControllers[appartementId];

      // Mise à jour des notes à partir des TextEditingController
      if (noteController != null) {
        details.note = noteController.text;
      }

      // Mise à jour de l'ordre des appartements et de l'état libre/pas libre
      var order = ordreAppartements[appartementId];
      if (order != null) {
        details.ordreAppartements = order;
      }
      // Aucune modification supplémentaire n'est requise ici pour 'estLibre' car il est déjà mis à jour dans l'UI

      detailsWithOrder[appartementId] = details;
    }

    // Affichez l'indicateur de chargement
    setState(() {
      isSaving = true;
    });

    try {
      // Créez une instance de Commande
      Commande nouvelleCommande = Commande(
        id: widget.commandeExistante?.id ?? '', // Utilisez l'ID existant s'il s'agit d'une mise à jour
        entrepriseId: widget.entrepriseId,
        nomResidence: widget.residence.nom,
        residenceId: widget.residence.id,
        dateCommande: selectedDate ?? DateTime.now(),
        appartements: appartements.where((a) => selectedAppartements[a.id] ?? false).toList(),
        detailsAppartements: detailsWithOrder,
        equipes: [], // Si vous avez des données d'équipe, ajoutez-les ici
        validation: {}, ordreAppartements: {}, personnelIds: [], // Ajoutez les données de validation si nécessaire
      );

      // Enregistrez ou mettez à jour la commande dans Firestore
      if (widget.commandeExistante != null) {
        await FirebaseFirestore.instance.collection('commandes').doc(nouvelleCommande.id).update(nouvelleCommande.toMap());
      } else {
        await FirebaseFirestore.instance.collection('commandes').add(nouvelleCommande.toMap());
      }

      // Affichez un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Commande enregistrée avec succès"))
      );

      // Naviguez vers la page d'accueil ou toute autre page appropriée
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      // Gérez les erreurs d'enregistrement
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'enregistrement de la commande: $e"))
      );
    } finally {
      // Arrêtez l'indicateur de chargement
      setState(() {
        isSaving = false;
      });
    }
  }


  void updateOrder(String appartementId, int newOrder) {
    setState(() {
      // Met à jour le nouvel ordre pour l'appartement sélectionné
      ordreAppartements[appartementId] = newOrder;

      // Ajuste l'ordre des autres appartements
      appartements.forEach((autreAppart) {
        if (autreAppart.id != appartementId) {
          int currentOrder = ordreAppartements[autreAppart.id] ?? appartements.length;
          // Si l'ordre actuel de l'autre appartement est supérieur ou égal au nouvel ordre
          // et inférieur à l'ancien ordre, décrémenter son ordre
          if (currentOrder >= newOrder && currentOrder < ordreAppartements[appartementId]!) {
            ordreAppartements[autreAppart.id] = currentOrder + 1;
          }
          // Si l'ordre actuel est inférieur au nouvel ordre et supérieur ou égal à l'ancien ordre,
          // incrémenter son ordre
          else if (currentOrder <= newOrder && currentOrder > ordreAppartements[appartementId]!) {
            ordreAppartements[autreAppart.id] = currentOrder - 1;
          }
        }
      });

      // Trie la liste des appartements en fonction du nouvel ordre
      appartements.sort((a, b) => (ordreAppartements[a.id] ?? 0).compareTo(ordreAppartements[b.id] ?? 0));
    });
  }


  @override
  Widget build(BuildContext context) {
    String formattedDate = selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate!) : 'Sélectionnez une date';
    bool areAllSelected = appartements.every((appart) => selectedAppartements[appart.id] ?? false);

    void toggleSelectAll() {
      setState(() {
        if (areAllSelected) {
          selectedAppartements.updateAll((key, value) => false);
        } else {
          selectedAppartements.updateAll((key, value) => true);
        }
      });
    }

    void updateOrder(String appartementId, String value) {
      final order = int.tryParse(value);
      if (order != null) {
        setState(() {
          ordreAppartements[appartementId] = order;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Sélection et Détails des Appartements'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: toggleSelectAll,
                  child: Text(
                    areAllSelected ? 'Désélectionner tout' : 'Sélectionner tout',
                    style: TextStyle(color: Colors.white), // Couleur de texte en blanc
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Couleur de fond en noir
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5), // Moins arrondi, ajustez le rayon selon vos préférences
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    DateTime? chosenDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (chosenDate != null) {
                      setState(() {
                        selectedDate = chosenDate;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(formattedDate, style: TextStyle(color: Theme.of(context).primaryColor)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 200.0),
                  child: DataTable(
                    columnSpacing: 38.0,
                    dataRowHeight: 50.0,
                    headingRowColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        return Colors.grey[200]!;
                      },
                    ),
                    border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Sélection', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Appartement', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Prioritaire', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Note', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Type de Ménage', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ordre de Priorité', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('État Libre', style: TextStyle(fontWeight: FontWeight.bold))), // Nouvelle colonne
                    ],
                    rows: appartements.map<DataRow>((appart) {
                      final isSelected = selectedAppartements[appart.id] ?? false;
                      final details = appartementDetails[appart.id] ??= DetailsAppartement();
                      final noteController = noteControllers[appart.id] ??= TextEditingController(text: details.note);

                      return DataRow(
                        selected: isSelected,
                        color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.lightGreen.shade100;
                          }
                          return null;
                        }),
                        cells: <DataCell>[
                          DataCell(Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                selectedAppartements[appart.id] = value ?? false;
                              });
                            },
                          )),
                          DataCell(Text(appart.numero, style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Checkbox(
                            value: details.prioritaire,
                            onChanged: (bool? value) {
                              setState(() {
                                details.prioritaire = value!;
                              });
                            },
                          )),
                          DataCell(
                            Container(
                              width: 150,
                              child: TextField(
                                controller: noteController,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                  border: OutlineInputBorder(),
                                  hintText: 'Note',
                                ),
                              ),
                            ),
                          ),
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
                          DataCell(
                            Container(
                              width: 100,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                controller: ordreControllers[appart.id],
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                  border: OutlineInputBorder(),
                                  hintText: 'Ordre',
                                ),
                                onChanged: (value) {
                                  int? order = int.tryParse(value);
                                  if (order != null) {
                                    ordreAppartements[appart.id] = order;
                                  }
                                },
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              color: details.estLibre ? Colors.lightGreen.shade100 : Colors.red.shade100, // Couleur de fond
                              child: DropdownButton<bool>(
                                value: details.estLibre,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    details.estLibre = newValue!;
                                  });
                                },
                                items: <bool>[true, false]
                                    .map<DropdownMenuItem<bool>>((bool value) {
                                  return DropdownMenuItem<bool>(
                                    value: value,
                                    child: Text(value ? 'Libre' : 'Pas Libre'),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _enregistrerCommande,
        label: Text('Enregistrer la commande', style: TextStyle(color: Colors.white)),
        icon: Icon(Icons.check, color: Colors.white),
        backgroundColor: Colors.black,
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
          Text('Appartement ${appartement.numero}', style: Theme.of(context).textTheme.headlineLarge),
          // Complétez avec d'autres détails de l'appartement
        ],
      ),
    );
  }
}
