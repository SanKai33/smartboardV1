import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/commande.dart';
import 'models/detailAppartement.dart';

class HistoriqueCommandePage extends StatelessWidget {
  final Commande commande;

  HistoriqueCommandePage({required this.commande});

  @override
  Widget build(BuildContext context) {
    double avancement = calculerAvancement();

    return Scaffold(
      appBar: AppBar(
        title: Text('Historique de la Commande'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date de la commande: ${DateFormat('dd/MM/yyyy').format(commande.dateCommande)}'),
              SizedBox(height: 8),
              Text('Résidence: ${commande.nomResidence}'),
              SizedBox(height: 8),
              Text('Nombre d\'appartements: ${commande.appartements.length}'),
              SizedBox(height: 8),
              Text('Avancement: ${avancement.toStringAsFixed(0)}%'),
              SizedBox(height: 16),
              Text('Détails des Appartements:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...commande.appartements.map((appartement) {
                DetailsAppartement details = commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
                return Card(
                  child: ListTile(
                    title: Text('Appartement ${appartement.numero}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('État: ${details.etatValidation.isNotEmpty ? details.etatValidation : "Non validé"}'),
                        Text('Type de ménage: ${details.typeMenage}'),
                        Text('Note: ${details.note}'),
                        if (details.prioritaire) Icon(Icons.priority_high, color: Colors.red),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  double calculerAvancement() {
    int totalAppartements = commande.appartements.length;
    int appartementsFait = commande.detailsAppartements.values.where((details) => details.menageEffectue).length;
    return (appartementsFait / totalAppartements) * 100;
  }
}