import 'package:cloud_firestore/cloud_firestore.dart';

class Personnel {
  String id;
  String nom;
  String prenom;
  String email;
  String typeCompte;
  bool estSuperviseur;
  String? residenceAffectee;
  String entrepriseId;

  Personnel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.typeCompte,
    required this.estSuperviseur,
    this.residenceAffectee,
    required this.entrepriseId,
  });

  factory Personnel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Personnel(
      id: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      typeCompte: data['typeCompte'] ?? '',
      estSuperviseur: data['estSuperviseur'] ?? false,
      residenceAffectee: data['residenceAffectee'],
      entrepriseId: data['entrepriseId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'typeCompte': typeCompte,
      'estSuperviseur': estSuperviseur,
      'residenceAffectee': residenceAffectee,
      'entrepriseId': entrepriseId,
    };
  }
}

