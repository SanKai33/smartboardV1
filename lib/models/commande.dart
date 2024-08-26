import 'package:cloud_firestore/cloud_firestore.dart';
import 'appartement.dart';
import 'detailAppartement.dart';
import 'equipes.dart';

class Commande {
  String id;
  String entrepriseId;
  String nomResidence;
  String residenceId;
  DateTime dateCommande;
  List<Appartement> appartements;
  Map<String, DetailsAppartement> detailsAppartements;
  List<Equipe> equipes;
  Map<String, String> validation;
  List<String> personnelIds;
  String noteGlobale;

  Commande({
    required this.id,
    required this.entrepriseId,
    required this.nomResidence,
    required this.residenceId,
    required this.dateCommande,
    required this.appartements,
    required this.detailsAppartements,
    required this.equipes,
    required this.validation,
    required this.personnelIds,
    required this.noteGlobale, required Map ordreAppartements,
  });

  factory Commande.fromMap(Map<String, dynamic> map, String documentId) {
    return Commande(
      id: documentId,
      entrepriseId: map['entrepriseId'] ?? '',
      nomResidence: map['nomResidence'] ?? '',
      residenceId: map['residenceId'] ?? '',
      dateCommande: (map['dateCommande'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appartements: (map['appartements'] as List<dynamic>? ?? []).map((e) => Appartement.fromMap(e as Map<String, dynamic>, e['id'] ?? '')).toList(),
      detailsAppartements: (map['detailsAppartements'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, DetailsAppartement.fromMap(value))) ?? {},
      equipes: (map['equipes'] as List<dynamic>? ?? []).map((e) => Equipe.fromMap(e as Map<String, dynamic>)).toList(),
      validation: Map<String, String>.from(map['validation'] ?? {}),
      personnelIds: List<String>.from(map['personnelIds'] ?? []),
      noteGlobale: map['noteGlobale'] ?? '', ordreAppartements: {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entrepriseId': entrepriseId,
      'nomResidence': nomResidence,
      'residenceId': residenceId,
      'dateCommande': Timestamp.fromDate(dateCommande),
      'appartements': appartements.map((x) => x.toMap()).toList(),
      'detailsAppartements': detailsAppartements.map((key, value) => MapEntry(key, value.toMap())),
      'equipes': equipes.map((x) => x.toMap()).toList(),
      'validation': validation,
      'personnelIds': personnelIds,
      'noteGlobale': noteGlobale,
    };
  }
}



