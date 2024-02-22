import 'package:cloud_firestore/cloud_firestore.dart';

class Residence {
  String id;
  String nom;
  String adresse;
  String entrepriseId;
  String imageUrl;
  List<String> personnelIds; // Ajout pour stocker les identifiants du personnel

  Residence({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.entrepriseId,
    this.imageUrl = '',
    this.personnelIds = const [], // Initialisation par défaut
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'adresse': adresse,
      'entrepriseId': entrepriseId,
      'imageUrl': imageUrl,
      'personnelIds': personnelIds, // Ajout de la liste des identifiants du personnel
    };
  }

  static Residence fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Residence(
      id: doc.id,
      nom: data['nom'] ?? '',
      adresse: data['adresse'] ?? '',
      entrepriseId: data['entrepriseId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      personnelIds: List<String>.from(data['personnelIds'] ?? []), // Récupération de la liste des identifiants du personnel
    );
  }
}


