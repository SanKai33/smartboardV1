class Entreprise {
  String id; // L'identifiant unique de l'entreprise, correspondant à l'UID Firebase de l'utilisateur
  String nom; // Le nom de l'entreprise
  String? email; // L'email associé au compte de l'entreprise (peut être null pour l'authentification par téléphone)
  String? telephone; // Numéro de téléphone associé au compte (facultatif)

  Entreprise({
    required this.id,
    required this.nom,
    this.email, // Rendu optionnel
    this.telephone, // Nouveau champ optionnel
  });

  // Méthode pour convertir une instance d'Entreprise en Map, pour l'enregistrement dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'email': email, // Peut être null
      'telephone': telephone, // Nouveau champ
    };
  }

  // Méthode pour créer une instance d'Entreprise à partir d'une Map
  factory Entreprise.fromMap(Map<String, dynamic> map, String documentId) {
    return Entreprise(
      id: documentId,
      nom: map['nom'] ?? '',
      email: map['email'], // Peut être null
      telephone: map['telephone'], // Nouveau champ
    );
  }
}
