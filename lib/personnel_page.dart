import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/creer_personnel.dart';
import 'package:smartboard/models/personnel.dart';

class PersonnelPage extends StatelessWidget {
  final String entrepriseId;

  PersonnelPage({required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Nombre d'onglets
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(text: 'Personnel de Nettoyage'),
              Tab(text: 'Contrôle et Réception'),
            ],
          ),
          title: Text('Gestion du Personnel'),
        ),
        body: TabBarView(
          children: [
            PersonnelNettoyageWidget(entrepriseId: entrepriseId),
            ControleReceptionWidget(entrepriseId: entrepriseId),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreerPersonnelPage(entrepriseId: entrepriseId)),
            );
          },
          child: Icon(Icons.person_add),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class PersonnelNettoyageWidget extends StatelessWidget {
  final String entrepriseId;

  PersonnelNettoyageWidget({required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('personnel')
          .where('entrepriseId', isEqualTo: entrepriseId)
          .where('type', isEqualTo: 'personnel de nettoyage')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erreur lors du chargement du personnel de nettoyage.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<Personnel> listePersonnel = snapshot.data!.docs.map((DocumentSnapshot document) {
          return Personnel.fromFirestore(document);
        }).toList();

        return ListView(
          children: listePersonnel.map((personnel) {
            return Card(
              child: ListTile(
                title: Text('${personnel.nom} ${personnel.prenom}'),
                subtitle: personnel.estSuperviseur ? Text('Superviseur') : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class ControleReceptionWidget extends StatelessWidget {
  final String entrepriseId;

  ControleReceptionWidget({required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('personnel')
          .where('entrepriseId', isEqualTo: entrepriseId)
          .where('type', isEqualTo: 'contrôle et réception')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erreur lors du chargement du personnel de contrôle et réception.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<Personnel> listePersonnel = snapshot.data!.docs.map((DocumentSnapshot document) {
          return Personnel.fromFirestore(document);
        }).toList();

        return ListView(
          children: listePersonnel.map((personnel) {
            return Card(
              child: ListTile(
                title: Text('${personnel.nom} ${personnel.prenom}'),
                subtitle: Text('Résidence: ${personnel.residenceAffectee ?? 'Non affecté'}'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}