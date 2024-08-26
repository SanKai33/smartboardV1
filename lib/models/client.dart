import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  String id;
  String nom;
  String prenom;
  String email;
  String telephone;
  String entrepriseId;
  List<String> residencesAffectees;
  bool estControleur;
  String identityCardUrl; // Nouveau champ pour URL de la carte d'identité
  String drivingLicenseUrl; // Nouveau champ pour URL du permis de conduire
  List<String> otherFilesUrls; // Nouveau champ pour les autres fichiers

  Client({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.entrepriseId,
    required this.residencesAffectees,
    required this.estControleur,
    this.identityCardUrl = '',
    this.drivingLicenseUrl = '',
    this.otherFilesUrls = const [],
  });

  factory Client.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Client(
      id: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'] ?? '',
      entrepriseId: data['entrepriseId'] ?? '',
      residencesAffectees: List<String>.from(data['residencesAffectees'] ?? []),
      estControleur: data['estControleur'] ?? false,
      identityCardUrl: data['identityCardUrl'] ?? '',
      drivingLicenseUrl: data['drivingLicenseUrl'] ?? '',
      otherFilesUrls: List<String>.from(data['otherFilesUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'entrepriseId': entrepriseId,
      'residencesAffectees': residencesAffectees,
      'estControleur': estControleur,
      'identityCardUrl': identityCardUrl,
      'drivingLicenseUrl': drivingLicenseUrl,
      'otherFilesUrls': otherFilesUrls,
    };
  }

  Client copyWith({
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? entrepriseId,
    List<String>? residencesAffectees,
    bool? estControleur,
    String? identityCardUrl,
    String? drivingLicenseUrl,
    List<String>? otherFilesUrls,
  }) {
    return Client(
      id: this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      residencesAffectees: residencesAffectees ?? this.residencesAffectees,
      estControleur: estControleur ?? this.estControleur,
      identityCardUrl: identityCardUrl ?? this.identityCardUrl,
      drivingLicenseUrl: drivingLicenseUrl ?? this.drivingLicenseUrl,
      otherFilesUrls: otherFilesUrls ?? this.otherFilesUrls,
    );
  }
}