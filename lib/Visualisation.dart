import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'models/appartement.dart';
import 'models/commande.dart';
import 'models/detailAppartement.dart';
import 'models/personnel.dart';


class VisualiserCommandePage extends StatefulWidget {
  final String commandeId;
  final Commande commande;

  VisualiserCommandePage({required this.commandeId, required this.commande});

  @override
  _VisualiserCommandePageState createState() => _VisualiserCommandePageState();
}

class _VisualiserCommandePageState extends State<VisualiserCommandePage> {
  late String commandeId;
  late Commande commande;

  @override
  void initState() {
    super.initState();
    commandeId = widget.commandeId;
    commande = widget.commande;
  }

  Future<List<Personnel>> _fetchPersonnel(String residenceId) async {
    QuerySnapshot personnelSnapshot = await FirebaseFirestore.instance
        .collection('personnel')
        .where('residenceAffectee', isEqualTo: residenceId)
        .get();

    return personnelSnapshot.docs
        .map((doc) => Personnel.fromFirestore(doc))
        .toList();
  }

  Future<List<Appartement>> _fetchAppartements(String residenceId) async {
    QuerySnapshot appartementSnapshot = await FirebaseFirestore.instance
        .collection('appartements')
        .where('residenceId', isEqualTo: residenceId)
        .get();

    return appartementSnapshot.docs
        .map((doc) => Appartement.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> _createPdf(Commande commande) async {
    final pdf = pw.Document();

    List<Personnel> personnelList = await _fetchPersonnel(commande.residenceId);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          int totalLitsSimples = commande.appartements.fold(0, (sum, a) => sum + a.nombreLitsSimples);
          int totalLitsDoubles = commande.appartements.fold(0, (sum, a) => sum + a.nombreLitsDoubles);
          int totalSallesDeBains = commande.appartements.fold(0, (sum, a) => sum + a.nombreSallesDeBains);
          int totalMenages = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Ménage').length;
          int totalRecouches = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Recouche').length;
          int totalDegraissages = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Dégraissage').length;
          int totalFermetures = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Fermeture').length;

          return <pw.Widget>[
            pw.Header(level: 0, child: pw.Text('Détails de la Commande')),
            pw.Paragraph(text: 'Résidence: ${commande.nomResidence}'),
            pw.Paragraph(text: 'Date de la commande: ${DateFormat('dd/MM/yyyy').format(commande.dateCommande)}'),
            pw.Paragraph(text: 'Nombre total d\'appartements: ${commande.appartements.length}'),

            pw.Header(level: 1, child: pw.Text('Détails des Appartements')),
            pw.Table.fromTextArray(
              context: context,
              headerAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>['Ordre', 'Numéro', 'Typologie', 'Bâtiment', 'Note de l\'Appartement', 'Modification', 'Est Libre'],
                ...commande.appartements.map((appartement) {
                  final details = commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
                  return [
                    details.ordreAppartements.toString(),
                    appartement.numero,
                    appartement.typologie,
                    appartement.batiment,
                    details.note,
                    details.etatModification != null && details.dateModification != null
                        ? '${details.etatModification} le ${DateFormat('dd/MM/yyyy HH:mm').format(details.dateModification!)}'
                        : 'Aucune',
                    details.estLibre ? 'Oui' : 'Non', // Affichage de l'état de disponibilité
                  ];
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Header(level: 1, child: pw.Text('Résumé des Types de Ménage')),
            pw.Table.fromTextArray(
              context: context,
              headerAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>['Type', 'Total', 'Type de Ménage', 'Total'],
                ['Lits Simples', '$totalLitsSimples', 'Ménages', '$totalMenages'],
                ['Lits Doubles', '$totalLitsDoubles', 'Recouches', '$totalRecouches'],
                ['Salles de Bains', '$totalSallesDeBains', 'Dégraissages', '$totalDegraissages'],
                ['', '', 'Fermetures', '$totalFermetures'],
              ],
            ),

            pw.Header(level: 1, child: pw.Text('Personnel Affecté')),
            pw.Table.fromTextArray(
              context: context,
              headerAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>['Nom', 'Prénom', 'Téléphone', 'Équipe', 'Présence'],
                ...personnelList.map((personnel) {
                  String equipe = _trouverEquipePourPersonnel(personnel.id, commande);
                  return [
                    personnel.nom,
                    personnel.prenom,
                    personnel.telephone,
                    equipe,
                    personnel.statutPresence,
                  ];
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Commande-${commande.nomResidence}.pdf');
  }

  String _trouverEquipePourPersonnel(String personnelId, Commande commande) {
    for (var equipe in commande.equipes) {
      if (equipe.personnelIds.contains(personnelId)) {
        return equipe.nom;
      }
    }
    return 'Aucune';
  }

  Future<void> _confirmDeleteCommande(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // L'utilisateur doit appuyer sur un bouton pour fermer la boîte de dialogue
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation de suppression'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Êtes-vous sûr de vouloir supprimer cette commande ?'),
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
                _deleteCommande(widget.commandeId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCommande(String commandeId) async {
    try {
      await FirebaseFirestore.instance.collection('commandes').doc(commandeId).delete();
      await _sendNotification("Commande supprimée", "La commande $commandeId a été supprimée.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Commande supprimée avec succès")),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la suppression de la commande: $e")),
      );
    }
  }

  Future<void> _removeAppartementFromCommande(String appartementId) async {
    try {
      setState(() {
        commande.appartements.removeWhere((app) => app.id == appartementId);
        commande.detailsAppartements[appartementId]?.dateModification = DateTime.now();
        commande.detailsAppartements[appartementId]?.etatModification = 'Supprimé';
      });
      await FirebaseFirestore.instance.collection('commandes').doc(commandeId).update(commande.toMap());
      await _sendNotification("Appartement supprimé", "L'appartement $appartementId a été supprimé de la commande.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Appartement supprimé de la commande avec succès")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la suppression de l'appartement: $e")),
      );
    }
  }

  Future<void> _addAppartementToCommande(Appartement appartement) async {
    setState(() {
      commande.appartements.add(appartement);
      commande.detailsAppartements[appartement.id] = DetailsAppartement(
        dateModification: DateTime.now(),
        etatModification: 'Ajouté',
      );
    });
    await FirebaseFirestore.instance.collection('commandes').doc(commandeId).update(commande.toMap());
    await _sendNotification("Appartement ajouté", "L'appartement ${appartement.numero} a été ajouté à la commande.");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Appartement ajouté à la commande avec succès")),
    );
  }

  void _showAddAppartementDialog() async {
    List<Appartement> allAppartements = await _fetchAppartements(commande.residenceId);
    List<Appartement> availableAppartements = allAppartements.where((app) =>
    !commande.appartements.any((commApp) => commApp.id == app.id)).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajouter un appartement'),
          content: Container(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableAppartements.length,
              itemBuilder: (context, index) {
                Appartement appartement = availableAppartements[index];
                return ListTile(
                  title: Text(appartement.numero),
                  subtitle: Text(appartement.typologie),
                  trailing: IconButton(
                    icon: Icon(Icons.add, color: Colors.black),
                    onPressed: () {
                      _addAppartementToCommande(appartement);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateNoteForAppartement(String appartementId, String note) async {
    try {
      await FirebaseFirestore.instance.collection('commandes').doc(commandeId).update({
        'detailsAppartements.$appartementId.note': note,
        'detailsAppartements.$appartementId.dateModification': FieldValue.serverTimestamp(),
        'detailsAppartements.$appartementId.etatModification': 'Modifié',
      });

      setState(() {
        commande.detailsAppartements[appartementId]?.note = note;
        commande.detailsAppartements[appartementId]?.dateModification = DateTime.now();
        commande.detailsAppartements[appartementId]?.etatModification = 'Modifié';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Note modifiée avec succès")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la modification de la note: $e")),
      );
    }
  }

  Future<void> _updateEstLibreForAppartement(String appartementId, bool estLibre) async {
    try {
      await FirebaseFirestore.instance.collection('commandes').doc(commandeId).update({
        'detailsAppartements.$appartementId.estLibre': estLibre,
        'detailsAppartements.$appartementId.dateModification': FieldValue.serverTimestamp(),
        'detailsAppartements.$appartementId.etatModification': 'Modifié',
      });

      setState(() {
        commande.detailsAppartements[appartementId]?.estLibre = estLibre;
        commande.detailsAppartements[appartementId]?.dateModification = DateTime.now();
        commande.detailsAppartements[appartementId]?.etatModification = 'Modifié';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("État de disponibilité modifié avec succès")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la modification de l'état de disponibilité: $e")),
      );
    }
  }

  Future<void> _updateOrdreForAppartement(String appartementId, int ordre) async {
    try {
      await FirebaseFirestore.instance.collection('commandes').doc(commandeId).update({
        'detailsAppartements.$appartementId.ordreAppartements': ordre,
        'detailsAppartements.$appartementId.dateModification': FieldValue.serverTimestamp(),
        'detailsAppartements.$appartementId.etatModification': 'Modifié',
      });

      setState(() {
        commande.detailsAppartements[appartementId]?.ordreAppartements = ordre;
        commande.detailsAppartements[appartementId]?.dateModification = DateTime.now();
        commande.detailsAppartements[appartementId]?.etatModification = 'Modifié';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ordre de priorité modifié avec succès")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la modification de l'ordre de priorité: $e")),
      );
    }
  }

  Future<void> _sendNotification(String titre, String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'entrepriseId': widget.commande.entrepriseId,
      'titre': titre,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la Commande'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _createPdf(widget.commande);
                      } catch (e) {
                        print('Erreur lors de la création du PDF: $e');
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Extraire le PDF', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed: () {
                      _confirmDeleteCommande(context);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Supprimer la Commande', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('commandes').doc(widget.commandeId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Erreur lors du chargement des données."));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text("Aucune donnée disponible."));
                }
                Commande commande = Commande.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Résidence: ${commande.nomResidence}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Date de la commande: ${DateFormat('dd/MM/yyyy').format(commande.dateCommande)}', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 10),
                        Text('Nombre total d\'appartements: ${commande.appartements.length}', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: _showAddAppartementDialog,
                              child: Row(
                                children: [
                                  Icon(Icons.add, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text('Ajouter appartement', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: buildDataTable(commande),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: buildSummaryTable(commande),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: buildPersonnelTable(commande),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDataTable(Commande commande) {
    return DataTable(
      columnSpacing: 38.0,
      dataRowHeight: 60.0, // Augmenté pour espacer les lignes
      headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        return Colors.grey[200]!;
      }),
      border: TableBorder.all(
        color: Colors.grey[300]!,
        width: 1,
      ),
      columns: const <DataColumn>[
        DataColumn(label: Text('Numéro', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Typologie', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Bâtiment', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('État de Validation', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Note', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Ordre', style: TextStyle(fontWeight: FontWeight.bold))), // Nouvelle colonne pour l'ordre
        DataColumn(label: Text('Modification', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Est Libre', style: TextStyle(fontWeight: FontWeight.bold))), // Nouvelle colonne
        DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))), // Column for the delete icon
      ],
      rows: commande.appartements.map<DataRow>((appartement) {
        DetailsAppartement details = commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
        return DataRow(
          cells: [
            DataCell(Text(appartement.numero)),
            DataCell(Text(appartement.typologie)),
            DataCell(Text(appartement.batiment)),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getColorForStatus(details.etatValidation),
                  ),
                ),
                SizedBox(width: 8),
                Text(details.etatValidation ?? "Non validé"),
              ],
            )),
            DataCell(
              TextFormField(
                initialValue: details.note,
                onFieldSubmitted: (value) {
                  _updateNoteForAppartement(appartement.id, value);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Note',
                ),
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            DataCell(
              TextFormField(
                initialValue: details.ordreAppartements.toString(),
                onFieldSubmitted: (value) {
                  int? newOrder = int.tryParse(value);
                  if (newOrder != null) {
                    _updateOrdreForAppartement(appartement.id, newOrder);
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Ordre',
                ),
                style: TextStyle(color: Colors.blue),
                keyboardType: TextInputType.number,
              ),
            ),
            DataCell(Text(details.etatModification != null && details.dateModification != null
                ? '${details.etatModification} le ${DateFormat('dd/MM/yyyy HH:mm').format(details.dateModification!)}'
                : 'Aucune')),
            DataCell(
              Checkbox(
                value: details.estLibre,
                onChanged: (bool? value) {
                  _updateEstLibreForAppartement(appartement.id, value ?? true);
                },
              ),
            ),
            DataCell(
              IconButton(
                icon: Icon(Icons.delete, color: Colors.black),
                onPressed: () {
                  _removeAppartementFromCommande(appartement.id);
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color getColorForStatus(String? status) {
    if (status == null) {
      return Colors.grey;
    }

    switch (status) {
      case 'Ménage validé':
        return Colors.blue;
      case 'Contrôle validé':
        return Colors.green;
      case 'Retour':
        return Colors.red;
      default:
        print("Statut non reconnu: $status");
        return Colors.grey;
    }
  }

  Widget buildSummaryTable(Commande commande) {
    int totalLitsSimples = commande.appartements.fold(0, (sum, a) => sum + a.nombreLitsSimples);
    int totalLitsDoubles = commande.appartements.fold(0, (sum, a) => sum + a.nombreLitsDoubles);
    int totalSallesDeBains = commande.appartements.fold(0, (sum, a) => sum + a.nombreSallesDeBains);
    int totalMenages = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Ménage').length;
    int totalRecouches = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Recouche').length;
    int totalDegraissages = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Dégraissage').length;
    int totalFermetures = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Fermeture').length;

    return Row(
      children: [
        Expanded(
          child: DataTable(
            columnSpacing: 20.0,
            dataRowHeight: 30.0,
            headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
              return Colors.grey[200]!;
            }),
            border: TableBorder.all(color: Colors.grey[300]!, width: 1),
            columns: const <DataColumn>[
              DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: [
              DataRow(cells: [DataCell(Text('Lits Simples')), DataCell(Text('$totalLitsSimples'))]),
              DataRow(cells: [DataCell(Text('Lits Doubles')), DataCell(Text('$totalLitsDoubles'))]),
              DataRow(cells: [DataCell(Text('Salles de Bains')), DataCell(Text('$totalSallesDeBains'))]),
            ],
          ),
        ),
        Expanded(
          child: DataTable(
            columnSpacing: 20.0,
            dataRowHeight: 30.0,
            headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
              return Colors.grey[200]!;
            }),
            border: TableBorder.all(color: Colors.grey[300]!, width: 1),
            columns: const <DataColumn>[
              DataColumn(label: Text('Type de Ménage', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: [
              DataRow(cells: [DataCell(Text('Ménages')), DataCell(Text('$totalMenages'))]),
              DataRow(cells: [DataCell(Text('Recouches')), DataCell(Text('$totalRecouches'))]),
              DataRow(cells: [DataCell(Text('Dégraissages')), DataCell(Text('$totalDegraissages'))]),
              DataRow(cells: [DataCell(Text('Fermetures')), DataCell(Text('$totalFermetures'))]),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildPersonnelTable(Commande commande) {
    return FutureBuilder<List<Personnel>>(
      future: _fetchPersonnel(commande.residenceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Text('Erreur ou données non disponibles');
        }
        var personnelList = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20.0,
            dataRowHeight: 30.0,
            headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
              return Colors.grey[200]!;
            }),
            border: TableBorder.all(color: Colors.grey[300]!, width: 1),
            columns: const [
              DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Prénom', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Équipe', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Présence', style: TextStyle(fontWeight: FontWeight.bold))), // Nouvelle colonne pour la présence
            ],
            rows: personnelList.map((personnel) {
              String equipe = _trouverEquipePourPersonnel(personnel.id, commande);
              return DataRow(
                cells: [
                  DataCell(Text(personnel.nom)),
                  DataCell(Text(personnel.prenom)),
                  DataCell(Text(personnel.telephone)),
                  DataCell(Text(equipe)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: personnel.statutPresence == 'présent' ? Colors.green : Colors.red,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(personnel.statutPresence),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}