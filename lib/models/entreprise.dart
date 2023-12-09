class Entreprise {
  String id; // L'identifiant unique de l'entreprise, correspondant à l'UID Firebase de l'utilisateur
  String nom; // Le nom de l'entreprise
  String email; // L'email associé au compte de l'entreprise
  // Vous pouvez ajouter d'autres champs selon les besoins de votre application

  Entreprise({
    required this.id,
    required this.nom,
    required this.email,
    // Autres champs si nécessaire
  });

  // Méthode pour convertir une instance d'Entreprise en Map, pour l'enregistrement dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'email': email,
      // Autres champs si nécessaire
    };
  }

  // Méthode pour créer une instance d'Entreprise à partir d'une Map, comme lors de la récupération des données de Firestore
  factory Entreprise.fromMap(Map<String, dynamic> map, String documentId) {
    return Entreprise(
      id: documentId,
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      // Autres champs si nécessaire
    );
  }
}
