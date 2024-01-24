import 'package:cloud_firestore/cloud_firestore.dart';

class Personnel {
  String id;
  String identifiant; // Ajout d'un champ identifiant pour la connexion
  String nom;
  String prenom;
  String email;
  String telephone;
  String typeCompte;
  bool estSuperviseur;
  String? residenceAffectee;
  String entrepriseId;

  Personnel({
    required this.id,
    required this.identifiant, // Initialisation du nouveau champ
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.typeCompte,
    required this.estSuperviseur,
    this.residenceAffectee,
    required this.entrepriseId,
  });

  factory Personnel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Personnel(
      id: doc.id,
      identifiant: data['identifiant'] ?? '', // Récupération de l'identifiant
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'] ?? '',
      typeCompte: data['typeCompte'] ?? '',
      estSuperviseur: data['estSuperviseur'] ?? false,
      residenceAffectee: data['residenceAffectee'],
      entrepriseId: data['entrepriseId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identifiant': identifiant, // Ajout de l'identifiant dans la Map
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'typeCompte': typeCompte,
      'estSuperviseur': estSuperviseur,
      'residenceAffectee': residenceAffectee,
      'entrepriseId': entrepriseId,
    };
  }
}

