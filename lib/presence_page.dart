import 'dart:io';



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'models/personnel.dart';
import 'package:pdf/widgets.dart' as pw;


import 'models/presence.dart';
import 'models/residence.dart';

class PresencePage extends StatefulWidget {
  final String entrepriseId;

  PresencePage({required this.entrepriseId});

  @override
  _PresencePageState createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _today = DateTime.now();
  bool _isAfternoon = DateTime.now().hour >= 12;
  Map<String, bool> _presentMorning = {};

  @override
  void initState() {
    super.initState();
    _chargerPresences();
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    return picked;
  }

  void _chargerPresences() async {
    DateTime today = DateTime.now();
    DateTime startOfDay = DateTime(today.year, today.month, today.day);
    DateTime endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    var snapshot = await _firestore.collection('fichesPresence')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .limit(1) // Supposer qu'il n'y a qu'une seule fiche de présence par jour
        .get();

    if (snapshot.docs.isNotEmpty) {
      var fichePresence = FichePresence.fromFirestore(snapshot.docs.first);

      // Mettre à jour l'état avec les données de présence du matin
      setState(() {
        _presentMorning = fichePresence.statutPresenceMatin; // Utiliser le nouveau champ
      });
    }
  }

  Future<void> _generatePdfForDate(DateTime date) async {
    final pdf = pw.Document();
    List<pw.Widget> widgets = [];

    var residencesSnapshot = await FirebaseFirestore.instance.collection('residences')
        .where('entrepriseId', isEqualTo: widget.entrepriseId)
        .get();

    for (var residenceDoc in residencesSnapshot.docs) {
      var residence = Residence.fromFirestore(residenceDoc);
      var personnelsSnapshot = await FirebaseFirestore.instance.collection('personnel')
          .where(FieldPath.documentId, whereIn: residence.personnelIds)
          .get();

      List<List<String>> personnelData = [
        <String>['Nom', 'Prénom', 'Téléphone'], // En-tête du tableau
      ];

      for (var personnelDoc in personnelsSnapshot.docs) {
        var personnel = Personnel.fromFirestore(personnelDoc);
        personnelData.add([personnel.nom, personnel.prenom, personnel.telephone]);
      }

      widgets.add(pw.Header(level: 0, text: residence.nom));
      widgets.add(pw.Paragraph(text: "Adresse: ${residence.adresse}"));
      //widgets.add(pw.Table.fromTextArray(context: pdf.context, data: personnelData));
      widgets.add(pw.Divider());
    }

    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (pw.Context context) => widgets));

    // Enregistrez le fichier PDF et partagez-le
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Rapport_${DateFormat('yyyy-MM-dd').format(date)}.pdf');
  }

  void _createPdf(List<Residence> residences) async {
    final pdf = pw.Document();

    for (var residence in residences) {
      // Ajouter un titre pour chaque résidence
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(residence.nom, style: pw.TextStyle(fontSize: 18)),
            ),
            pw.Paragraph(text: "Adresse: ${residence.adresse}"),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Nom', 'Prénom', 'Téléphone'], // En-tête du tableau
                // Ajouter les données pour chaque personnel ici
                ...residence.personnelIds.map((personnelId) {
                  // Vous devez récupérer les détails du personnel par personnelId
                  // Ceci est un exemple, remplacez-le par votre logique de récupération de données
                  return <String>[
                    'Nom du Personnel',
                    'Prénom du Personnel',
                    'Numéro de Téléphone',
                  ];
                }),
              ],
            ),
          ],
        ),
      );
    }

    // Enregistrez ou affichez le PDF
    try {
      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String path = '$dir/presences_${DateTime.now().toIso8601String()}.pdf';
      final File file = File(path);

      await file.writeAsBytes(await pdf.save());
      print("PDF sauvegardé à $path");
      // Vous pouvez maintenant partager ou ouvrir ce fichier PDF selon vos besoins
    } catch (e) {
      print("Erreur lors de la sauvegarde du PDF : $e");
    }
  }



  void _validerPresence(String personnelId, bool isAfternoon) async {
    var docRef = _firestore.collection('fichesPresence').doc('ID_DE_LA_FICHE');

    await _firestore.runTransaction((transaction) async {
      var docSnapshot = await transaction.get(docRef);
      if (!docSnapshot.exists) {
        // Si la fiche n'existe pas pour aujourd'hui, créez-en une nouvelle
        transaction.set(docRef, {
          'date': Timestamp.fromDate(DateTime.now()),
          'statutPresenceMatin': {},
          'statutPresenceApresMidi': {},
        });
      }
      var fichePresence = FichePresence.fromFirestore(docSnapshot);

      // Mise à jour de la présence selon la période de la journée
      if (isAfternoon) {
        fichePresence.statutPresenceApresMidi[personnelId] = true;
      } else {
        fichePresence.statutPresenceMatin[personnelId] = true;
      }

      // Mise à jour Firestore
      transaction.update(docRef, {
        'statutPresenceMatin': fichePresence.statutPresenceMatin,
        'statutPresenceApresMidi': fichePresence.statutPresenceApresMidi,
      });
    });

    // Mise à jour de l'interface utilisateur
    if (!isAfternoon) {
      setState(() {
        _presentMorning[personnelId] = true;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche de Présence - ${DateFormat('dd/MM/yyyy').format(_today)}'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              DateTime? date = await _selectDate(context);
              if (date != null) {
                _generatePdfForDate(date);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              // Logique pour afficher l'historique des présences
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Nombre de présents ce matin : ${_presentMorning.values.where((present) => present).length}'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('residences')
                  .where('entrepriseId', isEqualTo: widget.entrepriseId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      return _buildResidenceCard(doc);
                    }).toList(),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenceCard(DocumentSnapshot doc) {
    Residence residence = Residence.fromFirestore(doc);

    return Card(
      elevation: 4.0,
      margin: EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListTile(
            title: Text(residence.nom, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(residence.adresse ?? 'Adresse non disponible'),
          ),
          Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: residence.personnelIds.length,
            itemBuilder: (context, index) {
              String personnelId = residence.personnelIds[index];

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('personnel').doc(personnelId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                    Personnel personnel = Personnel.fromFirestore(snapshot.data!);

                    return ListTile(
                      title: Text('${personnel.nom} ${personnel.prenom}'),
                      subtitle: Text('Téléphone : ${personnel.telephone}'),
                      trailing: ElevatedButton(
                        onPressed: () => _validerPresence(personnelId, _isAfternoon),
                        child: Text('Valider la présence'),
                      ),
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}


