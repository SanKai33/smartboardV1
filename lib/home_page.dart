import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartboard/creer_commande.dart';
import 'package:smartboard/validation_menage_page.dart';
import 'historique_commande_page.dart';
import 'models/commande.dart';
import 'models/entreprise.dart';

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
        appBar: !kIsWeb ? AppBar(
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/images/icon.png'),
              ),
              SizedBox(width: 10),
              FutureBuilder<String>(
                future: _fetchEntrepriseName(entrepriseId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  return Text(snapshot.data ?? '');
                },
              ),
              Spacer(),

            ],
          ),
        ) : null,
        body: kIsWeb ? Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10.0, right: 10.0),
              child: Align(
                alignment: Alignment.topRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreerCommande(entrepriseId: entrepriseId)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Pour s'assurer que le Row ne prend que l'espace nécessaire
                    children: [
                      Icon(Icons.add, color: Colors.white), // Icône
                      SizedBox(width: 8), // Espace entre l'icône et le texte
                      Text(
                        'Nouvelle Commande',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Moins arrondi, ajustez selon vos préférences
                    ),
                  ),
                ),
              ),
            ),
            // Bandeau de design "Commandes en cours"
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Couleur plus claire et douce
                  borderRadius: BorderRadius.circular(20), // Coins plus arrondis
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5), // Ombre subtile
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, 4), // Légèrement décalée
                    ),
                  ],
                ),
                child: Text(
                  'Commandes en cours',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Couleur de texte simple
                  ),
                ),
              ),
            ),

            Expanded(
              child: CommandesEnCoursWidget(entrepriseId: entrepriseId),
            ),
          ],
        ) : Stack(
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
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreerCommande(entrepriseId: entrepriseId))),
                child: Icon(Icons.add),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
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
              child: ListTile(
                title: Text(commande.nomResidence),
                subtitle: Text('${DateFormat('dd/MM/yyyy – kk:mm').format(commande.dateCommande.toLocal())}'),
                trailing: Text('${pourcentageAvancement.toStringAsFixed(0)}% avancé'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ValidationMenagePage(commande: commande),
                  ));
                },
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
          children: commandes.map((commande) => Card(
            elevation: 4,
            margin: EdgeInsets.all(8),
            color: Colors.white, // Couleur bleu clair pour la carte
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
          )).toList(),
        );
      },
    );
  }
}
