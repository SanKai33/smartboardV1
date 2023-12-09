import 'package:cloud_firestore/cloud_firestore.dart';


class Residence {
  String id;
  String nom;
  String adresse;
  String entrepriseId;  // Ajout du champ entrepriseId

  Residence({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.entrepriseId,  // Inclusion dans le constructeur
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'adresse': adresse,
      'entrepriseId': entrepriseId,  // Inclusion dans toMap
    };
  }

  static Residence fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Residence(
      id: doc.id,
      nom: data['nom'] ?? '',
      adresse: data['adresse'] ?? '',
      entrepriseId: data['entrepriseId'] ?? '',  // Récupération de l'entrepriseId
    );
  }
}



