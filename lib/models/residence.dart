import 'package:cloud_firestore/cloud_firestore.dart';

class Residence {
  String id;
  String nom;
  String adresse;
  String entrepriseId;
  String imageUrl;  // Ajout du champ pour l'URL de l'image

  Residence({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.entrepriseId,
    this.imageUrl = '',  // Initialisation par défaut de l'URL de l'image
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'adresse': adresse,
      'entrepriseId': entrepriseId,
      'imageUrl': imageUrl,  // Inclusion de l'URL de l'image
    };
  }

  static Residence fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Residence(
      id: doc.id,
      nom: data['nom'] ?? '',
      adresse: data['adresse'] ?? '',
      entrepriseId: data['entrepriseId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',  // Récupération de l'URL de l'image
    );
  }
}


