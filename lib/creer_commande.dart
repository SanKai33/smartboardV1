
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/selection_appartement_page.dart';
import 'models/residence.dart';

class CreerCommande extends StatelessWidget {
  final String entrepriseId;

  CreerCommande({required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer une Commande'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Modifier la requête pour filtrer les résidences par entrepriseId
        stream: FirebaseFirestore.instance
            .collection('residences')
            .where('entrepriseId', isEqualTo: entrepriseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Une erreur s\'est produite'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune résidence trouvée pour cette entreprise'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Residence residence = Residence.fromFirestore(document);
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(residence.nom),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectionAppartementPage(
                          entrepriseId: entrepriseId,
                          residence: residence,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
