
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/selection_appartement_page.dart';
import 'models/residence.dart';

class CreerCommande extends StatelessWidget {
  final String entrepriseId;

  CreerCommande({required this.entrepriseId});

  Future<int> _getNombreAppartements(String residenceId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('appartements')
        .where('residenceId', isEqualTo: residenceId)
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer une Commande'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Veuillez sélectionner une résidence',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView(
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Residence residence = Residence.fromFirestore(document);
                    String imageUrl = residence.imageUrl;
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: residence.imageUrl.isNotEmpty
                              ? NetworkImage(residence.imageUrl as String)  // Cast en String
                              : AssetImage('path/to/placeholder_image.png') as ImageProvider,
                          radius: 25,
                        ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
