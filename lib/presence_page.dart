import 'dart:html' as html; // Import pour le téléchargement web
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';  // Pour les appels téléphoniques
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
  Map<String, bool> _presenceStatus = {};
  int _totalAgents = 0;
  int _totalPresents = 0;

  @override
  void initState() {
    super.initState();
    _loadPresence();
    _calculateTotalPresence();
  }

  Future<void> _loadPresence() async {
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    var snapshot = await _firestore.collection('fichesPresence')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var fichePresence = FichePresence.fromFirestore(snapshot.docs.first);

      setState(() {
        _presenceStatus = fichePresence.statutPresence;
      });
    } else {
      setState(() {
        _presenceStatus = {};
      });
    }
  }

  Future<void> _calculateTotalPresence() async {
    var personnelsSnapshot = await _firestore.collection('personnel')
        .where('entrepriseId', isEqualTo: widget.entrepriseId)
        .get();

    setState(() {
      _totalAgents = personnelsSnapshot.docs.length;
      _totalPresents = personnelsSnapshot.docs.where((doc) {
        String personnelId = doc.id;
        return _presenceStatus[personnelId] == true;
      }).length;
    });
  }

  Future<void> _loadPresenceForDate(DateTime date) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    var snapshot = await _firestore.collection('fichesPresence')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var fichePresence = FichePresence.fromFirestore(snapshot.docs.first);

      setState(() {
        _presenceStatus = fichePresence.statutPresence;
      });
    } else {
      setState(() {
        _presenceStatus = {};
      });
    }
    await _calculateTotalPresence();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche de Présence - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nombre de présents : $_totalPresents / $_totalAgents',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: () => _generatePdf(_selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Télécharger PDF',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
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
                      return _buildResidenceCard(Residence.fromFirestore(doc));
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

  Widget _buildResidenceCard(Residence residence) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('personnel')
          .where('residencesAffectees', arrayContains: residence.id)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Erreur de chargement');
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(4.0),
            ),
            elevation: 4.0,
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(residence.nom, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Aucun agent affecté'),
            ),
          );
        } else {
          int nbAgents = snapshot.data!.docs.length;
          int nbPresents = snapshot.data!.docs.where((doc) {
            String personnelId = doc.id;
            return _presenceStatus[personnelId] == true;
          }).length;

          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(4.0),
            ),
            elevation: 4.0,
            margin: EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  title: Text(residence.nom, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Agents affectés: $nbAgents\nPrésents: $nbPresents'),
                ),
                Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var personnelDoc = snapshot.data!.docs[index];
                    var personnel = Personnel.fromFirestore(personnelDoc);

                    return ListTile(
                      title: Text('${personnel.nom} ${personnel.prenom}', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          Text('Téléphone : ${personnel.telephone}'),
                          IconButton(
                            icon: Icon(Icons.phone, color: Colors.green),
                            onPressed: () {
                              _callPhoneNumber(personnel.telephone);
                            },
                          ),
                        ],
                      ),
                      trailing: Checkbox(
                        value: _presenceStatus[personnel.id] ?? false,
                        onChanged: (value) {
                          if (value != null) {
                            _validatePresence(personnel.id, value);
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }

  void _callPhoneNumber(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunch(launchUri.toString())) {
      await launch(launchUri.toString());
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  void _validatePresence(String personnelId, bool isPresent) async {
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    var snapshot = await _firestore.collection('fichesPresence')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var docId = snapshot.docs.first.id;
      var fichePresence = FichePresence.fromFirestore(snapshot.docs.first);

      fichePresence.statutPresence[personnelId] = isPresent;

      await _firestore.collection('fichesPresence').doc(docId).update(fichePresence.toMap());
    } else {
      var newFichePresence = FichePresence(
        id: '',
        date: _selectedDate,
        statutPresence: {personnelId: isPresent},
      );

      await _firestore.collection('fichesPresence').add(newFichePresence.toMap());
    }

    setState(() {
      _presenceStatus[personnelId] = isPresent;
      _calculateTotalPresence(); // Mise à jour du total des présences
    });
  }

  Future<void> _generatePdf(DateTime date) async {
    await _loadPresenceForDate(date);

    final pdfDoc = pw.Document();

    var residencesSnapshot = await _firestore.collection('residences')
        .where('entrepriseId', isEqualTo: widget.entrepriseId)
        .get();

    List<pw.Widget> allTables = [];

    for (var residenceDoc in residencesSnapshot.docs) {
      var residence = Residence.fromFirestore(residenceDoc);

      var personnelsSnapshot = await _firestore.collection('personnel')
          .where('residencesAffectees', arrayContains: residence.id)
          .get();

      List<List<String>> data = [
        ['Nom', 'Prénom', 'Téléphone', 'Présence']
      ];

      if (personnelsSnapshot.docs.isEmpty) {
        data.add(['Aucun agent', '', '', '']);
      } else {
        personnelsSnapshot.docs.forEach((personnelDoc) {
          var personnel = Personnel.fromFirestore(personnelDoc);
          bool isPresent = _presenceStatus[personnel.id] ?? false;
          data.add([
            personnel.nom,
            personnel.prenom,
            personnel.telephone,
            isPresent ? 'Présent' : 'Absent'
          ]);
        });
      }

      allTables.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(residence.nom, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(data: data, cellAlignment: pw.Alignment.centerLeft),
            pw.SizedBox(height: 20),
          ],
        ),
      );
    }

    pdfDoc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Fiche de Présence - ${DateFormat('dd/MM/yyyy').format(date)}',
                style: pw.TextStyle(fontSize: 24),
              ),
            ),
            pw.Text(
              'Nombre de présents : $_totalPresents / $_totalAgents',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            ...allTables,
          ],
        ),
      ),
    );

    final pdfBytes = await pdfDoc.save();
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'Fiche_Presence_${DateFormat('yyyyMMdd').format(date)}.pdf')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}