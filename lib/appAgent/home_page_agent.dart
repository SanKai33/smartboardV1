import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../historique_commande_page.dart';
import '../models/commande.dart';
import '../models/entreprise.dart';
import '../validation_menage_page.dart';

class HomePageAgent extends StatelessWidget {
  final String entrepriseId;

  HomePageAgent({required this.entrepriseId});

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
    return Scaffold(
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
          // Bandeau de design "Commandes en cours"
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Commandes en cours',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
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
              Expanded(
                child: CommandesEnCoursWidget(entrepriseId: entrepriseId),
              ),
            ],
          ),
        ],
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