import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main_screen.dart';
import '../models/appartement.dart';
import '../models/commande.dart';
import '../models/detailAppartement.dart';
import '../models/residence.dart';


class CombinedSelectionDetailsPage extends StatefulWidget {
  final String entrepriseId;
  final Residence residence;
  final Commande? commandeExistante;

  CombinedSelectionDetailsPage({required this.entrepriseId, required this.residence, this.commandeExistante});

  @override
  _CombinedSelectionDetailsPageState createState() => _CombinedSelectionDetailsPageState();
}

class _CombinedSelectionDetailsPageState extends State<CombinedSelectionDetailsPage> {
  DateTime? selectedDate;
  Map<String, bool> selectedAppartements = {};
  List<String> selectedOrder = [];
  Map<String, int> ordreAppartements = {};
  Map<String, DetailsAppartement> appartementDetails = {};
  List<Appartement> appartements = [];
  bool isLoading = true;
  Map<String, TextEditingController> ordreControllers = {};
  Map<String, TextEditingController> noteControllers = {};
  TextEditingController noteGlobaleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.commandeExistante != null) {
      _initializeWithExistingCommande(widget.commandeExistante!);
    } else {
      _loadAppartements();
    }
  }

  void _initializeWithExistingCommande(Commande commande) {
    setState(() {
      isLoading = false;
      selectedDate = commande.dateCommande;
      selectedAppartements.clear();
      appartementDetails.clear();
      noteControllers.clear();

      for (var appartement in commande.appartements) {
        selectedAppartements[appartement.id] = true;
        selectedOrder.add(appartement.id);

        if (commande.detailsAppartements.containsKey(appartement.id)) {
          var details = commande.detailsAppartements[appartement.id]!;
          appartementDetails[appartement.id] = details;
          noteControllers[appartement.id] = TextEditingController(text: details.note);
          ordreControllers[appartement.id] = TextEditingController(text: details.ordreAppartements.toString());
          ordreAppartements[appartement.id] = details.ordreAppartements;
        } else {
          appartementDetails[appartement.id] = DetailsAppartement();
          noteControllers[appartement.id] = TextEditingController();
        }
      }
      noteGlobaleController.text = commande.noteGlobale;
      _updateOrder();
    });
  }

  void _loadAppartements() async {
    setState(() {
      isLoading = true;
    });

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
          ordreAppartements[appart.id] = 0;
          noteControllers[appart.id] = TextEditingController();
          ordreControllers[appart.id] = TextEditingController(text: '0');
        }
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des appartements: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in noteControllers.values) {
      controller.dispose();
    }
    for (var controller in ordreControllers.values) {
      controller.dispose();
    }
    noteGlobaleController.dispose();
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

  Future<void> _selectDate(BuildContext context) async {
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
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    int selectedCount = selectedAppartements.values.where((isSelected) => isSelected).length;
    String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate!);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Date de la commande: $formattedDate'),
                Text('Nombre d\'appartements sélectionnés: $selectedCount'),
                Text('Résidence: ${widget.residence.nom}'),
              ],
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
              child: Text('Confirmer'),
              onPressed: () {
                Navigator.of(context).pop();
                _saveCommande();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCommande() async {
    var detailsWithOrder = Map<String, DetailsAppartement>.from(appartementDetails);
    for (var appartementId in detailsWithOrder.keys) {
      var details = detailsWithOrder[appartementId]!;
      var noteController = noteControllers[appartementId];

      if (noteController != null) {
        details.note = noteController.text;
      }

      var order = ordreAppartements[appartementId];
      if (order != null) {
        details.ordreAppartements = order;
      }

      detailsWithOrder[appartementId] = details;
    }

    setState(() {
      isSaving = true;
    });

    try {
      Commande nouvelleCommande = Commande(
        id: widget.commandeExistante?.id ?? '',
        entrepriseId: widget.entrepriseId,
        nomResidence: widget.residence.nom,
        residenceId: widget.residence.id,
        dateCommande: selectedDate ?? DateTime.now(),
        appartements: appartements.where((a) => selectedAppartements[a.id] ?? false).toList(),
        detailsAppartements: detailsWithOrder,
        equipes: [],
        validation: {},
        personnelIds: [],
        noteGlobale: noteGlobaleController.text, ordreAppartements: {},
      );

      if (widget.commandeExistante != null) {
        await FirebaseFirestore.instance.collection('commandes').doc(nouvelleCommande.id).update(nouvelleCommande.toMap());
      } else {
        await FirebaseFirestore.instance.collection('commandes').add(nouvelleCommande.toMap());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Commande enregistrée avec succès")),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainScreen(
            entrepriseId: widget.entrepriseId,
            agentId: '',
          ),
        ),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement de la commande: $e")),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> _enregistrerCommande() async {
    if (selectedDate == null) {
      await _selectDate(context);
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez sélectionner une date pour la commande.")),
      );
      return;
    }

    if (selectedAppartements.values.every((selected) => !selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aucun appartement sélectionné")),
      );
      return;
    }

    await _showConfirmationDialog(context);
  }

  void _updateOrder() {
    int currentOrder = 1;
    for (var appartId in selectedOrder) {
      if (selectedAppartements[appartId] == true) {
        ordreAppartements[appartId] = currentOrder;
        ordreControllers[appartId]?.text = currentOrder.toString();
        currentOrder++;
      } else {
        ordreAppartements[appartId] = 0;
        ordreControllers[appartId]?.text = '0';
      }
    }
    setState(() {});
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Appartement item = appartements.removeAt(oldIndex);
      appartements.insert(newIndex, item);
      _updateOrdreAppartements();
    });
  }

  void _updateOrdreAppartements() {
    int order = 1;
    for (var appartement in appartements) {
      if (selectedAppartements[appartement.id] == true) {
        ordreAppartements[appartement.id] = order;
        ordreControllers[appartement.id]?.text = order.toString();
        order++;
      } else {
        ordreAppartements[appartement.id] = 0;
        ordreControllers[appartement.id]?.text = '0';
      }
    }
    setState(() {});
  }

  void _resetOrder() {
    setState(() {
      for (var appartementId in selectedAppartements.keys) {
        if (selectedAppartements[appartementId] == true) {
          ordreAppartements[appartementId] = 0;
          ordreControllers[appartementId]?.text = '0';
        }
      }
      _updateOrder();
    });
  }

  int _calculateTotalLitsSimples() {
    return appartements
        .where((appart) => selectedAppartements[appart.id] ?? false)
        .fold(0, (total, appart) => total + appart.nombreLitsSimples);
  }

  int _calculateTotalLitsDoubles() {
    return appartements
        .where((appart) => selectedAppartements[appart.id] ?? false)
        .fold(0, (total, appart) => total + appart.nombreLitsDoubles);
  }

  int _calculateTotalSallesDeBain() {
    return appartements
        .where((appart) => selectedAppartements[appart.id] ?? false)
        .fold(0, (total, appart) => total + appart.nombreSallesDeBains);
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate!) : 'Sélectionnez une date';
    bool areAllSelected = appartements.every((appart) => selectedAppartements[appart.id] ?? false);
    int selectedCount = selectedAppartements.values.where((isSelected) => isSelected).length;

    void toggleSelectAll() {
      setState(() {
        if (areAllSelected) {
          selectedAppartements.updateAll((key, value) => false);
          selectedOrder.clear();
        } else {
          selectedAppartements.updateAll((key, value) => true);
          selectedOrder = appartements.map((a) => a.id).toList();
        }
        _updateOrder();
      });
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
            child: Center(
              child: Column(
                children: [
                  Text(
                    widget.residence.nom,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: toggleSelectAll,
                        child: Text(
                          areAllSelected ? 'Désélectionner tout' : 'Sélectionner tout',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
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
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    // Affichage du compteur d'appartements sélectionnés
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Appartements sélectionnés: $selectedCount', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              SizedBox(width: 500), // Ajuster la largeur pour aligner le bouton avec la colonne "Ordre de Priorité"
                              ElevatedButton(
                                onPressed: _resetOrder,
                                child: Text('Effacer Ordre de Priorité', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    DataTable(
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
                        DataColumn(label: Text('Bâtiment', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Prioritaire', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Note', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Type de Ménage', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Ordre de Priorité', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('État Libre', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: List<DataRow>.generate(
                        appartements.length,
                            (index) {
                          final appartement = appartements[index];
                          final isSelected = selectedAppartements[appartement.id] ?? false;
                          final details = appartementDetails[appartement.id] ??= DetailsAppartement();
                          final noteController = noteControllers[appartement.id] ??= TextEditingController(text: details.note);
                          final orderController = ordreControllers[appartement.id] ??= TextEditingController(text: ordreAppartements[appartement.id]?.toString() ?? '0');

                          return DataRow(
                            selected: isSelected,
                            color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                              if (isSelected) {
                                return Colors.lightGreen.shade50;
                              }
                              return null;
                            }),
                            cells: <DataCell>[
                              DataCell(
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      selectedAppartements[appartement.id] = value ?? false;
                                      if (value == true) {
                                        selectedOrder.add(appartement.id);
                                      } else {
                                        selectedOrder.remove(appartement.id);
                                      }
                                      _updateOrder();
                                    });
                                  },
                                ),
                              ),
                              DataCell(Text(appartement.numero, style: TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(appartement.batiment, style: TextStyle(fontWeight: FontWeight.bold))),
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
                                items: <String>['Ménage', 'Recouche', 'Dégraissage', 'Fermeture', 'Ouverture', 'Ménage à blanc']
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
                                    controller: orderController,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                      border: OutlineInputBorder(),
                                      hintText: 'Ordre',
                                    ),
                                    onChanged: (value) {
                                      int? order = int.tryParse(value);
                                      if (order != null) {
                                        ordreAppartements[appartement.id] = order;
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(
                                Switch(
                                  value: details.estLibre,
                                  onChanged: (bool value) {
                                    setState(() {
                                      details.estLibre = value;
                                    });
                                  },
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.red,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.6, // Ajuster la largeur pour qu'elle soit moins large
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Note Globale:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            TextField(
                              controller: noteGlobaleController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Écrire une note globale concernant la commande',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Affichage du total des lits simples, lits doubles et salles de bains
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Lits Simples: ${_calculateTotalLitsSimples()}', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Total Lits Doubles: ${_calculateTotalLitsDoubles()}', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Total Salles de Bain: ${_calculateTotalSallesDeBain()}', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Appartement ${appartement.numero}', style: Theme.of(context).textTheme.headlineLarge),
        ],
      ),
    );
  }
}