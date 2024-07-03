import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/presence.dart';

class HistoriquePresencePage extends StatelessWidget {
  final String entrepriseId;

  HistoriquePresencePage({required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique des Présences'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('historiquePresence')
            .where('entrepriseId', isEqualTo: entrepriseId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var fiches = snapshot.data!.docs.map((doc) => FichePresence.fromFirestore(doc)).toList();

          return ListView.builder(
            itemCount: fiches.length,
            itemBuilder: (context, index) {
              var fiche = fiches[index];
              return Card(
                elevation: 4.0,
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Date: ${DateFormat('dd/MM/yyyy').format(fiche.date)}'),
                  subtitle: Text('Présents: ${fiche.statutPresence.values.where((present) => present).length}'),
                  onTap: () => _showFicheDetails(context, fiche),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFicheDetails(BuildContext context, FichePresence fiche) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Détails de la Fiche de Présence'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${DateFormat('dd/MM/yyyy').format(fiche.date)}'),
                SizedBox(height: 8.0),
                Text('Présence:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...fiche.statutPresence.entries.map((entry) {
                  return Text('${entry.key}: ${entry.value ? "Présent" : "Absent"}');
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}