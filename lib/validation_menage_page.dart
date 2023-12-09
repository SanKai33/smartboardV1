import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'models/appartement.dart';
import 'models/commande.dart';





class ValidationMenagePage extends StatefulWidget {
  final Commande commande;

  ValidationMenagePage({required this.commande});

  @override
  _ValidationMenagePageState createState() => _ValidationMenagePageState();
}

class _ValidationMenagePageState extends State<ValidationMenagePage> {
  Map<String, bool> etatMenage = {};

  @override
  void initState() {
    super.initState();
    for (var appartement in widget.commande.appartements) {
      etatMenage[appartement.numero] = appartement.menageEffectue; // Supposons que vous avez ce champ dans votre modèle
    }
  }

  void _enregistrerMenage() {
    // TODO: Implémenter la logique pour enregistrer l'état du ménage
    // Marquer la commande comme complète si tous les ménages sont faits
    bool tousMenageEffectues = etatMenage.values.every((etat) => etat);
    if (tousMenageEffectues) {
      // TODO: Mettre à jour la commande dans votre base de données
    }

    // Afficher un message de succès ou naviguer vers une autre page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('État du ménage enregistré avec succès!')),
    );
    // Obtenir l'ID de l'entreprise de l'utilisateur courant
    String entrepriseId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Naviguer vers la page d'accueil
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(entrepriseId: entrepriseId))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Validation du Ménage'),
      ),
      body: ListView.builder(
        itemCount: widget.commande.appartements.length,
        itemBuilder: (context, index) {
          var appartement = widget.commande.appartements[index];
          return ListTile(
            title: Text('Appartement ${appartement.numero}'),
            trailing: Checkbox(
              value: etatMenage[appartement.numero],
              onChanged: (bool? value) {
                setState(() {
                  etatMenage[appartement.numero] = value ?? false;
                  // Si vous mettez à jour l'état dans Firestore, faites-le ici
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enregistrerMenage,
        child: Icon(Icons.save),
      ),
    );
  }
}