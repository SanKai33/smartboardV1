class Appartement {
  String id;
  String numero;
  String batiment;
  String typologie;
  int nombrePersonnes;
  String residenceId;
  bool menageEffectue;
  bool prioritaire;
  String note;
  String typeMenage;
  String etatValidation; // Nouvel attribut pour l'état de validation

  Appartement({
    required this.id,
    required this.numero,
    required this.batiment,
    required this.typologie,
    required this.nombrePersonnes,
    required this.residenceId,
    this.menageEffectue = false,
    this.prioritaire = false,
    this.note = '',
    this.typeMenage = 'Ménage',
    this.etatValidation = '', // Initialiser à une chaîne vide
  });

  factory Appartement.fromMap(Map<String, dynamic> map, String id) {
    return Appartement(
      id: id,
      numero: map['numero'] ?? '',
      batiment: map['batiment'] ?? '',
      typologie: map['typologie'] ?? '',
      nombrePersonnes: map['nombrePersonnes'] ?? 0,
      residenceId: map['residenceId'] ?? '',
      menageEffectue: map['menageEffectue'] ?? false,
      prioritaire: map['prioritaire'] ?? false,
      note: map['note'] ?? '',
      typeMenage: map['typeMenage'] ?? 'Ménage',
      etatValidation: map['etatValidation'] ?? '', // Ajout de l'état de validation
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'batiment': batiment,
      'typologie': typologie,
      'nombrePersonnes': nombrePersonnes,
      'residenceId': residenceId,
      'menageEffectue': menageEffectue,
      'prioritaire': prioritaire,
      'note': note,
      'typeMenage': typeMenage,
      'etatValidation': etatValidation, // Inclure l'état de validation
    };
  }

// Ajoutez des méthodes pour gérer les changements d'état si nécessaire
}