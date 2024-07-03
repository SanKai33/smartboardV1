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
  List<String> residencesAffectees; // Liste des résidences affectées
  String entrepriseId;
  String statutPresence; // Nouveau champ

  Personnel({
    required this.id,
    required this.identifiant,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.typeCompte,
    required this.estSuperviseur,
    required this.residencesAffectees,
    required this.entrepriseId,
    this.statutPresence = 'non présent', // Par défaut à "non présent"
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
      residencesAffectees: List<String>.from(data['residencesAffectees'] ?? []), // Liste des résidences affectées
      entrepriseId: data['entrepriseId'] ?? '',
      statutPresence: data['statutPresence'] ?? 'non présent',
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
      'residencesAffectees': residencesAffectees, // Liste des résidences affectées
      'entrepriseId': entrepriseId,
      'statutPresence': statutPresence,
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
    List<String>? residencesAffectees,
    String? entrepriseId,
    String? statutPresence,
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
      residencesAffectees: residencesAffectees ?? this.residencesAffectees,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      statutPresence: statutPresence ?? this.statutPresence,
    );
  }
}
