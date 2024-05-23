class Tarif {
  String idEntreprise; // L'identifiant de l'entreprise à laquelle le tarif est associé
  int niveauFormule; // Le niveau de la formule souscrite par l'entreprise
  double montant; // Montant total que l'entreprise doit payer

  Tarif({
    required this.idEntreprise,
    required this.niveauFormule,
    required this.montant,
  });

  // Méthode pour convertir une instance de Tarif en Map, pour l'enregistrement dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'idEntreprise': idEntreprise,
      'niveauFormule': niveauFormule,
      'montant': montant,
    };
  }

  // Méthode pour créer une instance de Tarif à partir d'une Map
  factory Tarif.fromMap(Map<String, dynamic> map) {
    return Tarif(
      idEntreprise: map['idEntreprise'] ?? '',
      niveauFormule: map['niveauFormule'] ?? 1, // Valeur par défaut: 1
      montant: map['montant']?.toDouble() ?? 0.0, // S'assurer que montant est converti en double
    );
  }
}