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
    };
  }
}