import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  String id;
  String nom;
  String prenom;
  String email;
  String telephone;
  String entrepriseId;
  String? residenceId;

  Client({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.entrepriseId,
    this.residenceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'entrepriseId': entrepriseId,
      'residenceId': residenceId,
    };
  }

  static Client fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'] ?? '',
      entrepriseId: data['entrepriseId'] ?? '',
      residenceId: data['residenceId'],
    );
  }
}

