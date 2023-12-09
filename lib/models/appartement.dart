
import 'package:cloud_firestore/cloud_firestore.dart';



class Appartement {
  String id;
  String numero;
  String batiment;
  String typologie;
  int nombrePersonnes;
  String residenceId;
  bool menageEffectue;
  bool prioritaire; // Ajout de la propriété 'prioritaire'
  String note; // Ajout de la propriété 'note'
  String typeMenage; // Ajout de la propriété 'typeMenage'

  Appartement({
    required this.id,
    required this.numero,
    required this.batiment,
    required this.typologie,
    required this.nombrePersonnes,
    required this.residenceId,
    this.menageEffectue = false,
    this.prioritaire = false, // Initialisation de la propriété 'prioritaire'
    this.note = '', // Initialisation de la propriété 'note'
    this.typeMenage = 'Ménage', // Initialisation de la propriété 'typeMenage'
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'batiment': batiment,
      'typologie': typologie,
      'nombrePersonnes': nombrePersonnes,
      'residenceId': residenceId,
      'menageEffectue': menageEffectue,
      'prioritaire': prioritaire, // Inclusion dans la map
      'note': note, // Inclusion dans la map
      'typeMenage': typeMenage, // Inclusion dans la map
    };
  }

  factory Appartement.fromMap(DocumentSnapshot doc) {
    var map = doc.data() as Map<String, dynamic>? ?? {};
    return Appartement(
      id: doc.id,
      numero: map['numero'] ?? '',
      batiment: map['batiment'] ?? '',
      typologie: map['typologie'] ?? '',
      nombrePersonnes: map['nombrePersonnes']?.toInt() ?? 0,
      residenceId: map['residenceId'] ?? '',
      menageEffectue: map['menageEffectue'] ?? false,
      prioritaire: map['prioritaire'] ?? false, // Récupération de la valeur
      note: map['note'] ?? '', // Récupération de la valeur
      typeMenage: map['typeMenage'] ?? 'Ménage', // Récupération de la valeur
    );
  }
}