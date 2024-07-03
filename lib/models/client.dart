import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  String id;
  String nom;
  String prenom;
  String email;
  String telephone;
  String entrepriseId;
  List<String> residencesAffectees; // Liste des résidences affectées
  bool estControleur; // Ajouté comme paramètre requis

  Client({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.entrepriseId,
    required this.residencesAffectees, // Liste des résidences affectées
    required this.estControleur, // Ajouté comme paramètre requis
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'entrepriseId': entrepriseId,
      'residencesAffectees': residencesAffectees, // Liste des résidences affectées
      'estControleur': estControleur, // Ajout à la méthode toMap
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
      residencesAffectees: List<String>.from(data['residencesAffectees'] ?? []), // Liste des résidences affectées
      estControleur: data['estControleur'] ?? false, // Récupération de la propriété depuis Firestore
    );
  }
}