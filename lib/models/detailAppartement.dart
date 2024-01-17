class DetailsAppartement {
  bool prioritaire;
  String note;
  String typeMenage;
  String etatValidation;
  bool menageEffectue;
  int ordreAppartements;
  bool estLibre; // Nouveau champ pour indiquer si l'appartement est libre ou pas

  DetailsAppartement({
    this.prioritaire = false,
    this.note = '',
    this.typeMenage = 'Ménage',
    this.etatValidation = '',
    this.menageEffectue = false,
    this.ordreAppartements = 0,
    this.estLibre = true, // Par défaut, l'appartement est considéré comme libre
  });

  factory DetailsAppartement.fromMap(Map<String, dynamic> map) {
    return DetailsAppartement(
      prioritaire: map['prioritaire'] ?? false,
      note: map['note'] ?? '',
      typeMenage: map['typeMenage'] ?? 'Ménage',
      etatValidation: map['etatValidation'] ?? '',
      menageEffectue: map['menageEffectue'] ?? false,
      ordreAppartements: map['ordreAppartements'] ?? 0,
      estLibre: map['estLibre'] ?? true, // Récupération de l'état "libre" de l'appartement
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prioritaire': prioritaire,
      'note': note,
      'typeMenage': typeMenage,
      'etatValidation': etatValidation,
      'menageEffectue': menageEffectue,
      'ordreAppartements': ordreAppartements,
      'estLibre': estLibre, // Ajout du champ dans la méthode toMap
    };
  }

  DetailsAppartement copyWith({
    bool? prioritaire,
    String? note,
    String? typeMenage,
    String? etatValidation,
    bool? menageEffectue,
    int? ordreAppartements,
    bool? estLibre, // Paramètre pour copyWith
  }) {
    return DetailsAppartement(
      prioritaire: prioritaire ?? this.prioritaire,
      note: note ?? this.note,
      typeMenage: typeMenage ?? this.typeMenage,
      etatValidation: etatValidation ?? this.etatValidation,
      menageEffectue: menageEffectue ?? this.menageEffectue,
      ordreAppartements: ordreAppartements ?? this.ordreAppartements,
      estLibre: estLibre ?? this.estLibre, // Mise à jour du champ estLibre
    );
  }

  @override
  String toString() {
    return 'DetailsAppartement(prioritaire: $prioritaire, note: $note, typeMenage: $typeMenage, etatValidation: $etatValidation, menageEffectue: $menageEffectue, ordreAppartements: $ordreAppartements, estLibre: $estLibre)';
  }
}
