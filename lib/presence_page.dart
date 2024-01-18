import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';




import 'models/commande.dart';
import 'models/personnel.dart';

class PresencePage extends StatefulWidget {
  @override
  _PresencePageState createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  List<Commande> commandes = []; // Votre liste de commandes
  int nombreDeCommandesDuJour = 0;
  Map<String, Personnel> personnelDetails = {};

  @override
  void initState() {
    super.initState();
    fetchCommandes(); // Appel à une fonction pour récupérer les commandes
  }

  void fetchCommandes() async {
    DateTime today = DateTime.now();
    DateTime todayDateOnly = DateTime(today.year, today.month, today.day);

    var querySnapshot = await FirebaseFirestore.instance.collection('commandes')
        .where('dateCommande', isGreaterThanOrEqualTo: Timestamp.fromDate(todayDateOnly))
        .where('dateCommande', isLessThan: Timestamp.fromDate(todayDateOnly.add(Duration(days: 1))))
        .get();

    List<Commande> fetchedCommandes = querySnapshot.docs.map((doc) {
      return Commande.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    // Récupération des détails du personnel pour chaque commande
    await fetchPersonnelDetails(fetchedCommandes);

    setState(() {
      commandes = fetchedCommandes;
    });
  }

  Future<void> fetchPersonnelDetails(List<Commande> commandes) async {
    Set<String> allPersonnelIds = commandes.expand((c) => c.personnelIds).toSet();
    for (String id in allPersonnelIds) {
      var doc = await FirebaseFirestore.instance.collection('personnel').doc(id).get();
      Personnel p = Personnel.fromFirestore(doc);
      personnelDetails[p.id] = p; // Stocke les détails du personnel dans la carte
    }
  }



  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }





  @override
  Widget build(BuildContext context) {
    String dateDuJour = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String qrData = "Presence_$dateDuJour";

    return Scaffold(
      appBar: AppBar(
        title: Text('Présence'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black, width: 0.5)),
            ),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 18),
                SizedBox(width: 8),
                Text(
                  dateDuJour,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 16),
                Icon(Icons.assignment_turned_in, size: 18),
                SizedBox(width: 8),
                Text(
                  "Cmds: ${commandes.length}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 16),
                Icon(Icons.people, size: 18),
              ],
            ),
          ),
          SizedBox(height: 20),
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 200.0,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: commandes.length,
              itemBuilder: (context, index) {
                Commande commande = commandes[index];
                List<Widget> personnelWidgets = commande.personnelIds.map((id) {
                  Personnel p = personnelDetails[id] ?? Personnel(id: id, nom: 'Inconnu', prenom: '', email: '', telephone: '', typeCompte: '', estSuperviseur: false, entrepriseId: '');
                  return Text('${p.prenom} ${p.nom}');
                }).toList();

                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(commande.nomResidence, style: TextStyle(fontWeight: FontWeight.bold)),
                      Divider(color: Colors.black),
                      ...personnelWidgets,
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



