import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartboard/selection_appartement_page.dart';

import 'Visualisation.dart';
import 'appWebEntreprise/creer_commande_web.dart';
import 'historique_commande_page.dart';
import 'models/commande.dart';
import 'models/entreprise.dart';
import 'models/residence.dart';
import 'validation_menage_page.dart';

class HomePage extends StatelessWidget {
  final String entrepriseId;

  HomePage({required this.entrepriseId});

  Future<String> _fetchEntrepriseName(String entrepriseId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('entreprises').doc(entrepriseId).get();
    if (snapshot.exists && snapshot.data() is Map) {
      Entreprise entreprise = Entreprise.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
      return entreprise.nom;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Suppression de l'AppBar pour toutes les versions
        appBar: null,
        body: kIsWeb
            ? Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Commandes en cours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: CommandesEnCoursWidget(entrepriseId: entrepriseId),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
            : Stack(
          children: [
            Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: 'Commandes en cours'),
                    Tab(text: 'Commandes passées'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      CommandesEnCoursWidget(entrepriseId: entrepriseId),
                      CommandesPasseesWidget(entrepriseId: entrepriseId),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CreerCommandePopup(entrepriseId: entrepriseId),
                      );
                    },
                  );
                },
                child: Icon(Icons.add),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        floatingActionButton: kIsWeb
            ? FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CreerCommandePopup(entrepriseId: entrepriseId),
                );
              },
            );
          },
          icon: Icon(Icons.add),
          label: Text('Créer Commande'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        )
            : null,
      ),
    );
  }
}

class CommandesEnCoursWidget extends StatelessWidget {
  final String entrepriseId;

  CommandesEnCoursWidget({required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('commandes')
          .where('entrepriseId', isEqualTo: entrepriseId)
          .where('dateCommande', isGreaterThanOrEqualTo: startOfDay)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur lors du chargement des commandes'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<Commande> commandes = snapshot.data!.docs
            .map((doc) => Commande.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        if (commandes.isEmpty) {
          return Center(
            child: Text(
              'Aucune commande en cours',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: commandes.length,
          itemBuilder: (context, index) {
            final commande = commandes[index];
            int totalAppartements = commande.appartements.length;
            int appartementsMenageFait = commande.detailsAppartements.values.where((details) => details.menageEffectue).length;
            double pourcentageAvancement = (totalAppartements > 0) ? (appartementsMenageFait / totalAppartements * 100) : 0.0;

            return Card(
              elevation: 4,
              margin: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ValidationMenagePage(commande: commande),
                      ));
                    },
                    child: ListTile(
                      title: Text(
                        commande.nomResidence,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${DateFormat('dd/MM/yyyy – kk:mm').format(commande.dateCommande.toLocal())}'),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${pourcentageAvancement.toStringAsFixed(0)}% avancé',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.remove_red_eye, color: Colors.black),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => VisualiserCommandePage(
                                commandeId: commande.id,
                                commande: commande,
                              ),
                            ));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class CommandesPasseesWidget extends StatelessWidget {
  final String entrepriseId;

  CommandesPasseesWidget({required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('commandes')
          .where('entrepriseId', isEqualTo: entrepriseId)
          .where('dateCommande', isLessThan: startOfDay)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur lors du chargement des commandes'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<Commande> commandes = snapshot.data!.docs
            .map((doc) => Commande.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return ListView(
          children: commandes
              .map(
                (commande) => Card(
              elevation: 4,
              margin: EdgeInsets.all(8),
              color: Colors.white,
              child: ListTile(
                title: Text(commande.nomResidence),
                subtitle: Text(DateFormat('yyyy-MM-dd – kk:mm').format(commande.dateCommande.toLocal())),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HistoriqueCommandePage(commande: commande),
                    ),
                  );
                },
              ),
            ),
          )
              .toList(),
        );
      },
    );
  }
}

class CreerCommandePopup extends StatelessWidget {
  final String entrepriseId;

  CreerCommandePopup({required this.entrepriseId});

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
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(residence.imageUrl),
                          radius: 25,
                        ),
                        title: Text(residence.nom),
                        onTap: () {
                          if (kIsWeb) { // Sur PC
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CombinedSelectionDetailsPage(
                                  entrepriseId: entrepriseId,
                                  residence: residence,
                                ),
                              ),
                            );
                          } else {
                            // Sur mobile, naviguer vers SelectionAppartementPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectionAppartementPage(
                                  entrepriseId: entrepriseId,
                                  residence: residence,
                                  agentId: '',
                                ),
                              ),
                            );
                          }
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
