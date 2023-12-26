import 'package:cloud_firestore/cloud_firestore.dart';

class Residence {
  String id;
  String nom;
  String adresse;
  String entrepriseId;
  String imageUrl;

  Residence({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.entrepriseId,
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'adresse': adresse,
      'entrepriseId': entrepriseId,
      'imageUrl': imageUrl,
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
    );
  }
}


