import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models/tarif.dart';

class TarificationPage extends StatefulWidget {
  final String entrepriseId; // ID de l'entreprise nécessaire pour le lien avec Tarif

  TarificationPage({required this.entrepriseId});

  @override
  _TarificationPageState createState() => _TarificationPageState();
}

class _TarificationPageState extends State<TarificationPage> {
  int nombreDeFormules = 1;  // Commence avec une formule de base
  double prixBase = 100.0;   // Prix de base pour la première formule

  @override
  void initState() {
    super.initState();
    chargerDonneesInitiales();
  }

  Future<void> chargerDonneesInitiales() async {
    var tarifDoc = await FirebaseFirestore.instance.collection('tarifs').doc(widget.entrepriseId).get();
    if (tarifDoc.exists) {
      setState(() {
        nombreDeFormules = tarifDoc.data()?['niveauFormule'] ?? 1;
        prixBase = tarifDoc.data()?['montant'] ?? 100.0;
      });
    }
  }

  void ajouterFormule() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmer l'ajout de formule"),
          content: Text("Ajouter une formule augmentera votre abonnement de 50€ par mois et vous permettra d'accéder à une résidence supplémentaire."),
          actions: <Widget>[
            TextButton(
              child: Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Confirmer"),
              onPressed: () {
                Navigator.of(context).pop();
                incrementerFormule();
              },
            ),
          ],
        );
      },
    );
  }

  void reduireFormule() {
    if (nombreDeFormules > 1) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirmer la réduction de formule"),
            content: Text("Pour réduire votre formule, vous devez d'abord supprimer les résidences excédentaires de votre abonnement."),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void incrementerFormule() {
    setState(() {
      nombreDeFormules++;
      enregistrerTarif(calculerPrixTotal());
    });
  }

  double calculerPrixTotal() {
    return prixBase + (nombreDeFormules - 1) * 50.0;
  }

  Future<void> enregistrerTarif(double nouveauPrix) async {
    await FirebaseFirestore.instance.collection('tarifs').doc(widget.entrepriseId).set({
      'niveauFormule': nombreDeFormules,
      'montant': nouveauPrix,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarification des Formules'),
      ),
      body: Center(
        child: Card(
          elevation: 4.0,
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Formule $nombreDeFormules', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Prix: ${calculerPrixTotal()}€', style: TextStyle(fontSize: 20, color: Colors.green)),
                SizedBox(height: 10),
                Text('Nombre de résidences autorisées: $nombreDeFormules', style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: ajouterFormule,
                  child: Text('Ajouter une formule', style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: reduireFormule,
                  child: Text('Réduire la formule', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Background color
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

