import 'package:cloud_firestore/cloud_firestore.dart';

class Personnel {
  String id;
  String identifiant;
  String nom;
  String prenom;
  String email;
  String telephone;
  String typeCompte;
  bool estSuperviseur;
  bool estControleur; // Nouvel attribut ajouté
  String? residenceAffectee;
  String entrepriseId;

  Personnel({
    required this.id,
    required this.identifiant,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.typeCompte,
    required this.estSuperviseur,
    required this.estControleur, // Ajouté comme paramètre requis
    this.residenceAffectee,
    required this.entrepriseId,
  });

  factory Personnel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Personnel(
      id: doc.id,
      identifiant: data['identifiant'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'] ?? '',
      typeCompte: data['typeCompte'] ?? '',
      estSuperviseur: data['estSuperviseur'] ?? false,
      estControleur: data['estControleur'] ?? false, // Récupération de la propriété depuis Firestore
      residenceAffectee: data['residenceAffectee'],
      entrepriseId: data['entrepriseId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identifiant': identifiant,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'typeCompte': typeCompte,
      'estSuperviseur': estSuperviseur,
      'estControleur': estControleur, // Ajout à la méthode toMap
      'residenceAffectee': residenceAffectee,
      'entrepriseId': entrepriseId,
    };
  }

  Personnel copyWith({
    String? identifiant,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? typeCompte,
    bool? estSuperviseur,
    bool? estControleur, // Nouvel attribut pour la méthode copyWith
    String? residenceAffectee,
    String? entrepriseId,
  }) {
    return Personnel(
      id: this.id,
      identifiant: identifiant ?? this.identifiant,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      typeCompte: typeCompte ?? this.typeCompte,
      estSuperviseur: estSuperviseur ?? this.estSuperviseur,
      estControleur: estControleur ?? this.estControleur, // Initialisation de estControleur
      residenceAffectee: residenceAffectee ?? this.residenceAffectee,
      entrepriseId: entrepriseId ?? this.entrepriseId,
    );
  }
}

