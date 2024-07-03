import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


import 'historique_commande_page.dart';

import 'models/commande.dart';

class CommandePasseeWeb extends StatefulWidget {
  final String entrepriseId;

  CommandePasseeWeb({required this.entrepriseId});

  @override
  _CommandePasseeWebState createState() => _CommandePasseeWebState();
}

class _CommandePasseeWebState extends State<CommandePasseeWeb> {
  TextEditingController searchController = TextEditingController();
  DateTimeRange? dateRange;

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    Stream<QuerySnapshot> _commandesStream = FirebaseFirestore.instance
        .collection('commandes')
        .where('entrepriseId', isEqualTo: widget.entrepriseId)
        .where('dateCommande', isLessThan: startOfDay)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Commandes Passées'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Chercher par nom de résidence',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && picked != dateRange) {
                      setState(() {
                        dateRange = picked;
                      });
                    }
                  },
                  child: Text('Filtrer par date'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _commandesStream,
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

                if (searchController.text.isNotEmpty) {
                  commandes = commandes.where((commande) {
                    return commande.nomResidence
                        .toLowerCase()
                        .contains(searchController.text.toLowerCase());
                  }).toList();
                }

                if (dateRange != null) {
                  commandes = commandes.where((commande) {
                    return commande.dateCommande.isAfter(dateRange!.start) &&
                        commande.dateCommande.isBefore(dateRange!.end.add(Duration(days: 1)));
                  }).toList();
                }

                if (commandes.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune commande passée',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: commandes.length,
                  itemBuilder: (context, index) {
                    final commande = commandes[index];

                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        title: Text(
                          commande.nomResidence,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${DateFormat('dd/MM/yyyy – kk:mm').format(commande.dateCommande.toLocal())}'),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => HistoriqueCommandePage(commande: commande),
                          ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}