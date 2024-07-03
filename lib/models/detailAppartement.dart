import 'package:cloud_firestore/cloud_firestore.dart';

class DetailsAppartement {
  bool prioritaire;
  String note;
  String typeMenage;
  String etatValidation;
  bool menageEffectue;
  int ordreAppartements;
  bool estLibre; // Nouveau champ pour indiquer si l'appartement est libre ou pas
  DateTime? dateModification; // Nouveau champ pour la date de modification
  String? etatModification; // Nouveau champ pour l'état de modification (ajouté/supprimé)

  DetailsAppartement({
    this.prioritaire = false,
    this.note = '',
    this.typeMenage = 'Ménage',
    this.etatValidation = '',
    this.menageEffectue = false,
    this.ordreAppartements = 0,
    this.estLibre = true, // Par défaut, l'appartement est considéré comme libre
    this.dateModification, // Par défaut, null
    this.etatModification, // Par défaut, null
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
      dateModification: map['dateModification'] != null ? (map['dateModification'] as Timestamp).toDate() : null, // Conversion du timestamp Firestore en DateTime
      etatModification: map['etatModification'], // Récupération de l'état de modification
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
      'dateModification': dateModification != null ? Timestamp.fromDate(dateModification!) : null, // Conversion de DateTime en timestamp Firestore
      'etatModification': etatModification, // Ajout du champ état de modification
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
    DateTime? dateModification, // Nouveau paramètre pour copyWith
    String? etatModification, // Nouveau paramètre pour copyWith
  }) {
    return DetailsAppartement(
      prioritaire: prioritaire ?? this.prioritaire,
      note: note ?? this.note,
      typeMenage: typeMenage ?? this.typeMenage,
      etatValidation: etatValidation ?? this.etatValidation,
      menageEffectue: menageEffectue ?? this.menageEffectue,
      ordreAppartements: ordreAppartements ?? this.ordreAppartements,
      estLibre: estLibre ?? this.estLibre, // Mise à jour du champ estLibre
      dateModification: dateModification ?? this.dateModification, // Mise à jour du champ dateModification
      etatModification: etatModification ?? this.etatModification, // Mise à jour du champ étatModification
    );
  }

  @override
  String toString() {
    return 'DetailsAppartement(prioritaire: $prioritaire, note: $note, typeMenage: $typeMenage, etatValidation: $etatValidation, menageEffectue: $menageEffectue, ordreAppartements: $ordreAppartements, estLibre: $estLibre, dateModification: $dateModification, etatModification: $etatModification)';
  }
}