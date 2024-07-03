import 'package:cloud_firestore/cloud_firestore.dart';



class FichePresence {
  String id;
  DateTime date;
  Map<String, bool> statutPresence; // Simplifié pour une seule présence

  FichePresence({
    required this.id,
    required this.date,
    required this.statutPresence,
  });

  factory FichePresence.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FichePresence(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      statutPresence: Map<String, bool>.from(data['statutPresence'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'statutPresence': statutPresence,
    };
  }
}
