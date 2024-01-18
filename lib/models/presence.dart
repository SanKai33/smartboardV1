import 'package:cloud_firestore/cloud_firestore.dart';

class FichePresence {
  String id; // Identifiant unique de la fiche de présence
  DateTime date; // Date de la fiche de présence
  Map<String, bool> statutPresence; // Carte des statuts de présence du personnel, clé = ID du personnel, valeur = statut de présence

  FichePresence({
    required this.id,
    required this.date,
    required this.statutPresence,
  });

  factory FichePresence.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convertir la carte de statut de présence
    Map<String, bool> statutPresence = {};
    if (data['statutPresence'] != null) {
      data['statutPresence'].forEach((key, value) {
        statutPresence[key] = value as bool;
      });
    }

    return FichePresence(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      statutPresence: statutPresence,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'statutPresence': statutPresence, // Convertir en format adapté à Firestore
    };
  }
}