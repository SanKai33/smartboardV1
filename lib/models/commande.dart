import 'package:cloud_firestore/cloud_firestore.dart';

import 'appartement.dart';
import 'equipes.dart';


class Commande {
  String id;
  String entrepriseId;
  String nomResidence;
  DateTime dateCommande;
  List<Appartement> appartements;
  Map<String, Map<String, dynamic>> detailsAppartements;
  List<Equipe> equipes;
  Map<String, String> validation;

  Commande({
    required this.id,
    required this.entrepriseId,
    required this.nomResidence,
    required this.dateCommande,
    required this.appartements,
    required this.detailsAppartements,
    required this.equipes,
    required this.validation,
  }) {
    // Initialisation d'une équipe par défaut si nécessaire
    if (equipes.isEmpty) {
      equipes.add(Equipe(nom: 'Équipe 1', appartementIds: appartements.map((a) => a.id).toList(), appartements: []));
    }
  }

  factory Commande.fromMap(Map<String, dynamic> map, String documentId) {
    return Commande(
      id: documentId,
      entrepriseId: map['entrepriseId'] ?? '',
      nomResidence: map['nomResidence'] ?? '',
      dateCommande: (map['dateCommande'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appartements: (map['appartements'] as List<dynamic>? ?? []).map((e) => Appartement.fromMap(e as Map<String, dynamic>, e['id'] ?? '')).toList(),
      detailsAppartements: Map<String, Map<String, dynamic>>.from(map['detailsAppartements'] ?? {}),
      equipes: (map['equipes'] as List<dynamic>? ?? []).map((e) => Equipe.fromMap(e as Map<String, dynamic>)).toList(),
      validation: Map<String, String>.from(map['validation'] ?? {}),
    );
  }

  String? get residenceId => null;

  Map<String, dynamic> toMap() {
    return {
      'entrepriseId': entrepriseId,
      'nomResidence': nomResidence,
      'dateCommande': Timestamp.fromDate(dateCommande),
      'appartements': appartements.map((x) => x.toMap()).toList(),
      'detailsAppartements': detailsAppartements,
      'equipes': equipes.map((x) => x.toMap()).toList(),
      'validation': validation,
    };
  }
}





