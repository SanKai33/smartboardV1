import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models/appartement.dart';
import 'models/commande.dart';



class ValidationMenagePage extends StatefulWidget {
  final Commande commande;

  ValidationMenagePage({required this.commande});

  @override
  _ValidationMenagePageState createState() => _ValidationMenagePageState();
}

class _ValidationMenagePageState extends State<ValidationMenagePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _updateMenageStatus(Appartement appartement, bool menageEffectue) async {
    // Mettre à jour l'état du ménage dans la base de données
    await _firestore
        .collection('commandes') // Le nom de votre collection
        .doc(widget.commande.id) // L'ID de la commande
        .update({
      'appartements': widget.commande.appartements.map((a) => a.toMap()).toList()
    });
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
          Appartement appartement = widget.commande.appartements[index];
          bool menageEffectue = appartement.menageEffectue;

          return Card(
            child: ListTile(
              title: Text('Appartement ${appartement.numero}'),
              subtitle: Text('Ménage effectué: ${menageEffectue ? "Oui" : "Non"}'),
              trailing: Checkbox(
                value: menageEffectue,
                onChanged: (bool? value) {
                  setState(() {
                    appartement.menageEffectue = value ?? false;
                    _updateMenageStatus(appartement, value ?? false);
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
