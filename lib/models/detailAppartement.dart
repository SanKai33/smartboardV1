class DetailsAppartement {
  bool prioritaire;
  String note;
  String typeMenage;
  String etatValidation; // État de validation de l'appartement
  bool menageEffectue; // Ajout du champ pour indiquer si le ménage a été effectué

  DetailsAppartement({
    this.prioritaire = false,
    this.note = '',
    this.typeMenage = 'Ménage',
    this.etatValidation = '',
    this.menageEffectue = false, // Initialisation par défaut
  });

  factory DetailsAppartement.fromMap(Map<String, dynamic> map) {
    return DetailsAppartement(
      prioritaire: map['prioritaire'] ?? false,
      note: map['note'] ?? '',
      typeMenage: map['typeMenage'] ?? 'Ménage',
      etatValidation: map['etatValidation'] ?? '',
      menageEffectue: map['menageEffectue'] ?? false, // Récupération de la valeur
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prioritaire': prioritaire,
      'note': note,
      'typeMenage': typeMenage,
      'etatValidation': etatValidation,
      'menageEffectue': menageEffectue, // Ajout du champ dans la méthode toMap
    };
  }
}
