import 'dart:io';
import 'package:barcode/barcode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models/personnel.dart';
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
  DateTime _selectedDate = DateTime.now();
  bool _isAfternoon = DateTime.now().hour >= 12;
  Map<String, bool> _presentMorning = {};
  Map<String, bool> _presentAfternoon = {};

  @override
  void initState() {
    super.initState();
    _chargerPresences();
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _chargerPresences();
    }
    return picked;
  }

  void _chargerPresences() async {
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    var snapshot = await _firestore.collection('fichesPresence')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var fichePresence = FichePresence.fromFirestore(snapshot.docs.first);

      setState(() {
        _presentMorning = fichePresence.statutPresenceMatin;
        _presentAfternoon = fichePresence.statutPresenceApresMidi;
      });
    } else {
      setState(() {
        _presentMorning = {};
        _presentAfternoon = {};
      });
    }
  }

  Future<void> _generatePdfForDate(DateTime date) async {
    final pdf = pw.Document();
    List<pw.Widget> widgets = [];

    // Ajouter un titre avec la date
    widgets.add(pw.Header(level: 0, text: 'Rapport de présence - ${DateFormat('dd/MM/yyyy').format(date)}'));

    var residencesSnapshot = await FirebaseFirestore.instance.collection('residences')
        .where('entrepriseId', isEqualTo: widget.entrepriseId)
        .get();

    for (var residenceDoc in residencesSnapshot.docs) {
      var residence = Residence.fromFirestore(residenceDoc);
      var personnelsSnapshot = await FirebaseFirestore.instance.collection('personnel')
          .where(FieldPath.documentId, whereIn: residence.personnelIds)
          .get();

      List<List<String>> personnelData = [
        <String>['Nom', 'Prénom', 'Téléphone', 'Présent Matin', 'Présent Après-midi'],
      ];

      for (var personnelDoc in personnelsSnapshot.docs) {
        var personnel = Personnel.fromFirestore(personnelDoc);
        var presentMorning = _presentMorning[personnelDoc.id] == true ? 'Oui' : 'Non';
        var presentAfternoon = _presentAfternoon[personnelDoc.id] == true ? 'Oui' : 'Non';
        personnelData.add([personnel.nom, personnel.prenom, personnel.telephone, presentMorning, presentAfternoon]);
      }

      widgets.add(pw.Header(level: 1, text: residence.nom));
      widgets.add(pw.Paragraph(text: "Adresse: ${residence.adresse}"));
      widgets.add(pw.Table.fromTextArray(data: personnelData));
      widgets.add(pw.Divider());
    }

    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (pw.Context context) => widgets));

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Rapport_${DateFormat('yyyy-MM-dd').format(date)}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Rapport_${DateFormat('yyyy-MM-dd').format(date)}.pdf');
  }

  void _validerPresence(String personnelId, bool isAfternoon) async {
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    var snapshot = await _firestore.collection('fichesPresence')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var docId = snapshot.docs.first.id;
      var fichePresence = FichePresence.fromFirestore(snapshot.docs.first);

      if (isAfternoon) {
        fichePresence.statutPresenceApresMidi[personnelId] = true;
      } else {
        fichePresence.statutPresenceMatin[personnelId] = true;
      }

      await _firestore.collection('fichesPresence').doc(docId).update(fichePresence.toMap());
    } else {
      var newFichePresence = FichePresence(
        id: '',
        date: _selectedDate,
        statutPresenceMatin: isAfternoon ? {} : {personnelId: true},
        statutPresenceApresMidi: isAfternoon ? {personnelId: true} : {},
      );

      await _firestore.collection('fichesPresence').add(newFichePresence.toMap());
    }

    setState(() {
      if (isAfternoon) {
        _presentAfternoon[personnelId] = true;
      } else {
        _presentMorning[personnelId] = true;
      }
    });
  }

  String _generateQRCodeData() {
    return 'https://example.com/validate?date=${DateFormat('yyyy-MM-dd').format(_selectedDate)}&id=${widget.entrepriseId}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche de Présence - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await _generatePdfForDate(_selectedDate);
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
          Center(
            child: _buildQrCode(),
          ),
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

  Widget _buildQrCode() {
    final qrCode = Barcode.qrCode();
    final qrData = _generateQRCodeData();

    final qrSvg = qrCode.toSvg(
      qrData,
      width: 200,
      height: 200,
      drawText: false,
    );

    return Container(
      width: 200,
      height: 200,
      child: SvgPicture.string(qrSvg),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: _isAfternoon ? _presentAfternoon[personnelId] ?? false : _presentMorning[personnelId] ?? false,
                            onChanged: (value) {
                              _validerPresence(personnelId, _isAfternoon);
                            },
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _validerPresence(personnelId, _isAfternoon);
                            },
                            child: Text('Valider'),
                          ),
                        ],
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