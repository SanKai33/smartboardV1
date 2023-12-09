import 'package:cloud_firestore/cloud_firestore.dart';


import 'appartement.dart';

class Commande {
  String id;
  String entrepriseId; // Identifiant unique de l'entreprise
  String nomResidence;
  DateTime dateCommande;
  List<Appartement> appartements; // Objets Appartement sélectionnés pour la commande
  Map<String, dynamic> detailsAppartements; // Détails pour chaque appartement

  Commande({
    required this.id,
    required this.entrepriseId,
    required this.nomResidence,
    required this.dateCommande,
    required this.appartements,
    required this.detailsAppartements,
  });

  // Convertir une Map en instance de Commande
  factory Commande.fromMap(Map<String, dynamic> map, String documentId) {
    return Commande(
      id: documentId,
      entrepriseId: map['entrepriseId'] ?? '',
      nomResidence: map['nomResidence'] ?? '',
      dateCommande: (map['dateCommande'] as Timestamp).toDate(),
      appartements: List<Appartement>.from(
          map['appartements']?.map((item) => Appartement.fromMap(item)) ?? []
      ),
      detailsAppartements: Map<String, dynamic>.from(map['detailsAppartements'] ?? {}),
    );
  }

  // Convertir un objet Commande en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'entrepriseId': entrepriseId,
      'nomResidence': nomResidence,
      'dateCommande': Timestamp.fromDate(dateCommande),
      'appartements': appartements.map((appartement) => appartement.toMap()).toList(),
      'detailsAppartements': detailsAppartements,
    };
  }
}

/**
class Commande {
  String id;
  String nomResidence;
  DateTime dateCommande;
  List<Appartement> appartements; // Objets Appartement sélectionnés pour la commande
  Map<String, Map<String, dynamic>> detailsAppartements;

  Commande({
    required this.id,
    required this.nomResidence,
    required this.dateCommande,
    required this.appartements,
    required this.detailsAppartements,
  });

  // Convertir une Map en instance de Commande
  factory Commande.fromMap(Map<String, dynamic> map, String documentId) {
    var appartementsList = map['appartements'] as List<dynamic>? ?? [];
    List<Appartement> appartements = appartementsList.map((appartementMap) {
      // La méthode fromMap est utilisée ici et s'attend à une Map<String, dynamic>
      return Appartement.fromMap(appartementMap as DocumentSnapshot<Object?>);
    }).toList();

    // Convertit le Timestamp de Firestore en DateTime
    var dateCommandeTimestamp = map['dateCommande'] as Timestamp;
    DateTime dateCommande = dateCommandeTimestamp.toDate();

    // Extrait les détails des appartements, si disponibles
    var detailsAppartementsMap = map['detailsAppartements'] as Map<String, dynamic>? ?? {};

    return Commande(
      id: documentId,
      nomResidence: map['nomResidence'] ?? '',
      dateCommande: dateCommande,
      appartements: appartements,
      detailsAppartements: detailsAppartementsMap.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value))),
    );
  }

  // Convertir un objet Commande en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'nomResidence': nomResidence,
      'dateCommande': Timestamp.fromDate(dateCommande), // Convertit DateTime en Firestore Timestamp
      'appartements': appartements.map((appartement) => appartement.toMap()).toList(),
      'detailsAppartements': detailsAppartements,
    };
  }
}**/




