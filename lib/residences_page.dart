import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/parametrer_page.dart';
import 'package:smartboard/parametrer_page_web.dart';
import 'models/appartement.dart';
import 'models/residence.dart';

class ResidencesPage extends StatelessWidget {
  final String entrepriseId;

  ResidencesPage({required this.entrepriseId});

  Future<List<Appartement>> _getAppartements(String residenceId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('appartements')
        .where('residenceId', isEqualTo: residenceId)
        .get();
    return snapshot.docs.map((doc) => Appartement.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  void _showAddResidenceDialog(BuildContext context) {
    final TextEditingController _nomController = TextEditingController();
    final TextEditingController _nombreAppartementsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter une résidence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _nomController,
                decoration: InputDecoration(labelText: 'Nom de la résidence'),
              ),
              TextField(
                controller: _nombreAppartementsController,
                decoration: InputDecoration(labelText: 'Nombre d\'appartements'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ajouter'),
              onPressed: () {
                // Ajouter la résidence dans Firebase
                final String nom = _nomController.text;
                final int nombreAppartements = int.tryParse(_nombreAppartementsController.text) ?? 0;

                if (nom.isNotEmpty) {
                  final residenceId = FirebaseFirestore.instance.collection('residences').doc().id;

                  FirebaseFirestore.instance.collection('residences').doc(residenceId).set({
                    'nom': nom,
                    'adresse': '', // Placeholder pour l'adresse, peut être modifié plus tard
                    'entrepriseId': entrepriseId,
                  }).then((_) {
                    // Ajouter les appartements à Firebase
                    for (int i = 0; i < nombreAppartements; i++) {
                      final appartementId = FirebaseFirestore.instance.collection('appartements').doc().id;
                      FirebaseFirestore.instance.collection('appartements').doc(appartementId).set({
                        'numero': '',
                        'batiment': '',
                        'typologie': '',
                        'nombrePersonnes': 0,
                        'residenceId': residenceId,
                        'nombreLitsSimples': 0,
                        'nombreLitsDoubles': 0,
                        'nombreSallesDeBains': 0,
                      });
                    }

                    // Naviguer vers la page de paramétrage après l'ajout
                    Navigator.of(context).pop();
                    if (kIsWeb) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ParametrerPageWeb(entrepriseId: entrepriseId, residence: Residence(id: residenceId, nom: nom, adresse: '', imageUrl: '', entrepriseId: ''))),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ParametrerPage(entrepriseId: entrepriseId, residence: Residence(id: residenceId, nom: nom, adresse: '', imageUrl: '', entrepriseId: ''))),
                      );
                    }
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Résidences'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          TextButton.icon(
            onPressed: () {
              _showAddResidenceDialog(context);
            },
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Nouvelle Résidence', style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0), // Moins arrondi
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('residences')
            .where('entrepriseId', isEqualTo: this.entrepriseId)
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

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.0), // Padding droite et gauche
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Residence residence = Residence.fromFirestore(document);
              return FutureBuilder<List<Appartement>>(
                future: _getAppartements(residence.id),
                builder: (context, appartementsSnapshot) {
                  if (appartementsSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (appartementsSnapshot.hasError) {
                    return Center(child: Text('Erreur lors du chargement des appartements'));
                  }

                  List<Appartement>? appartements = appartementsSnapshot.data;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        leading: CircleAvatar(
                          backgroundImage: residence.imageUrl.isNotEmpty
                              ? NetworkImage(residence.imageUrl as String)
                              : AssetImage('assets/images/placeholder.png') as ImageProvider,
                          radius: 30,
                        ),
                        title: Text(
                          residence.nom,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              residence.adresse,
                              style: TextStyle(fontSize: 14),
                            ),
                            if (appartements != null && appartements.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.king_bed, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '${appartements.map((a) => a.nombreLitsDoubles).reduce((a, b) => a + b)} lits doubles, ',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Icon(Icons.bed, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '${appartements.map((a) => a.nombreLitsSimples).reduce((a, b) => a + b)} lits simples, ',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Icon(Icons.bathtub, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '${appartements.map((a) => a.nombreSallesDeBains).reduce((a, b) => a + b)} salles de bains',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          if (kIsWeb) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ParametrerPageWeb(entrepriseId: entrepriseId, residence: residence)),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ParametrerPage(entrepriseId: entrepriseId, residence: residence)),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}