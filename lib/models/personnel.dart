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
  List<String> residencesAffectees;
  String entrepriseId;
  String statutPresence;
  String identityCardUrl; // Nouveau champ pour URL de la carte d'identité
  String drivingLicenseUrl; // Nouveau champ pour URL du permis de conduire
  List<String> otherFilesUrls; // Nouveau champ pour les autres fichiers

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
    this.statutPresence = 'non présent',
    this.identityCardUrl = '',
    this.drivingLicenseUrl = '',
    this.otherFilesUrls = const [],
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
      residencesAffectees: List<String>.from(data['residencesAffectees'] ?? []),
      entrepriseId: data['entrepriseId'] ?? '',
      statutPresence: data['statutPresence'] ?? 'non présent',
      identityCardUrl: data['identityCardUrl'] ?? '',
      drivingLicenseUrl: data['drivingLicenseUrl'] ?? '',
      otherFilesUrls: List<String>.from(data['otherFilesUrls'] ?? []),
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
      'residencesAffectees': residencesAffectees,
      'entrepriseId': entrepriseId,
      'statutPresence': statutPresence,
      'identityCardUrl': identityCardUrl,
      'drivingLicenseUrl': drivingLicenseUrl,
      'otherFilesUrls': otherFilesUrls,
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
    String? identityCardUrl,
    String? drivingLicenseUrl,
    List<String>? otherFilesUrls,
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
      identityCardUrl: identityCardUrl ?? this.identityCardUrl,
      drivingLicenseUrl: drivingLicenseUrl ?? this.drivingLicenseUrl,
      otherFilesUrls: otherFilesUrls ?? this.otherFilesUrls,
    );
  }
}
