import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/parametrer_page.dart';
import 'models/residence.dart';


class ResidencesPage extends StatelessWidget {
  final String entrepriseId;

  ResidencesPage({required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Résidences'),
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
            return Center(child: Text('Aucune résidence trouvée'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Residence residence = Residence.fromFirestore(document);
              return Card(
                child: ListTile(
                  title: Text(residence.nom),
                  subtitle: Text(residence.adresse),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ParametrerPage(entrepriseId: entrepriseId, residence: residence)),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ParametrerPage(entrepriseId: entrepriseId)),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}

