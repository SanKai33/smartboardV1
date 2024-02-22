import 'package:cloud_firestore/cloud_firestore.dart';

class FichePresence {
  String id; // Identifiant unique de la fiche de présence
  DateTime date; // Date de la fiche de présence
  Map<String, bool> statutPresenceMatin; // Carte des statuts de présence du personnel le matin
  Map<String, bool> statutPresenceApresMidi; // Carte des statuts de présence du personnel l'après-midi

  FichePresence({
    required this.id,
    required this.date,
    required this.statutPresenceMatin,
    required this.statutPresenceApresMidi,
  });

  factory FichePresence.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    Map<String, bool> statutPresenceMatin = {};
    Map<String, bool> statutPresenceApresMidi = {};
    if (data['statutPresenceMatin'] != null) {
      data['statutPresenceMatin'].forEach((key, value) {
        statutPresenceMatin[key] = value as bool;
      });
    }
    if (data['statutPresenceApresMidi'] != null) {
      data['statutPresenceApresMidi'].forEach((key, value) {
        statutPresenceApresMidi[key] = value as bool;
      });
    }

    return FichePresence(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      statutPresenceMatin: statutPresenceMatin,
      statutPresenceApresMidi: statutPresenceApresMidi,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'statutPresenceMatin': statutPresenceMatin,
      'statutPresenceApresMidi': statutPresenceApresMidi,
    };
  }
}
