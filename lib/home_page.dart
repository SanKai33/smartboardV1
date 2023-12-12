import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartboard/creer_commande.dart';
import 'package:smartboard/validation_menage_page.dart';
import 'messagerie.dart';
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
    return 'Nom de l\'entreprise';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              ),
              SizedBox(width: 10),
              FutureBuilder<String>(
                future: _fetchEntrepriseName(entrepriseId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  return Text(snapshot.data ?? 'Nom de l\'entreprise');
                },
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.messenger_outline),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MessageriePage())),
              ),
            ],
          ),
        ),
        body: Column(
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreerCommande(entrepriseId: entrepriseId))),
          child: Icon(Icons.add),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
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
            return Card(
              elevation: 4,
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text(commande.nomResidence),
                subtitle: Text(DateFormat('yyyy-MM-dd – kk:mm').format(commande.dateCommande)),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('entreprise')
          .doc(entrepriseId)
          .collection('commandes')
          .where('statut', isEqualTo: 'passée')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erreur lors du chargement des commandes');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<Commande> commandes = snapshot.data!.docs
            .map((doc) => Commande.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return ListView(
          children: commandes.map((commande) => ListTile(
            title: Text(commande.nomResidence),
            subtitle: Text(DateFormat('yyyy-MM-dd – kk:mm').format(commande.dateCommande.toLocal())),
            onTap: () {
              // Ajoutez ici la logique de navigation si nécessaire
            },
          )).toList(),
        );
      },
    );
  }
}
