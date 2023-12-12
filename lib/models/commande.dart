import 'package:cloud_firestore/cloud_firestore.dart';
import 'appartement.dart';


class Commande {
  String id;
  String entrepriseId;
  String nomResidence;
  DateTime dateCommande;
  List<Appartement> appartements;
  Map<String, Map<String, dynamic>> detailsAppartements;

  Commande({
    required this.id,
    required this.entrepriseId,
    required this.nomResidence,
    required this.dateCommande,
    required this.appartements,
    required this.detailsAppartements,
  });

  factory Commande.fromMap(Map<String, dynamic> map, String documentId) {
    return Commande(
      id: documentId,
      entrepriseId: map['entrepriseId'] ?? '',
      nomResidence: map['nomResidence'] ?? '',
      dateCommande: (map['dateCommande'] as Timestamp).toDate(),
      appartements: (map['appartements'] as List).map((e) {
        var appartementMap = e as Map<String, dynamic>;
        var appartementId = appartementMap['id'] as String? ?? '';
        return Appartement.fromMap(appartementMap, appartementId);
      }).toList(),
      detailsAppartements: Map<String, Map<String, dynamic>>.from(map['detailsAppartements']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entrepriseId': entrepriseId,
      'nomResidence': nomResidence,
      'dateCommande': Timestamp.fromDate(dateCommande),
      'appartements': appartements.map((x) => x.toMap()).toList(),
      'detailsAppartements': detailsAppartements,
    };
  }
}





