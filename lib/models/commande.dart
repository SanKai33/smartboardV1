import 'package:cloud_firestore/cloud_firestore.dart';
import '../creer_equipes.dart';
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

  Commande({
    required this.id,
    required this.entrepriseId,
    required this.nomResidence,
    required this.dateCommande,
    required this.appartements,
    required this.detailsAppartements,
    required this.equipes,
  });

  factory Commande.fromMap(Map<String, dynamic> map, String documentId) {
    return Commande(
      id: documentId,
      entrepriseId: map['entrepriseId'] ?? '',
      nomResidence: map['nomResidence'] ?? '',
      dateCommande: (map['dateCommande'] as Timestamp).toDate(),
      appartements: (map['appartements'] as List).map((e) {
        var appartementMap = e as Map<String, dynamic>;
        return Appartement.fromMap(appartementMap, appartementMap['id'] as String? ?? '');
      }).toList(),
      detailsAppartements: Map<String, Map<String, dynamic>>.from(map['detailsAppartements']),
      equipes: (map['equipes'] as List? ?? []).map((e) {
        if (e is Map<String, dynamic>) {
          return Equipe.fromMap(e);
        } else {
          throw 'Type de données inattendu pour une équipe: ${e.runtimeType}';
        }
      }).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entrepriseId': entrepriseId,
      'nomResidence': nomResidence,
      'dateCommande': Timestamp.fromDate(dateCommande),
      'appartements': appartements.map((x) => x.toMap()).toList(),
      'detailsAppartements': detailsAppartements,
      'equipes': equipes.map((x) => x.toMap()).toList(),
    };
  }
}






