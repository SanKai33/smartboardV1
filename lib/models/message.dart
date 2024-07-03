import 'package:cloud_firestore/cloud_firestore.dart';



class Message {
  String id;
  String commandeId;
  String senderId;
  String senderName;
  String text;
  String imageUrl;
  DateTime timestamp;

  Message({
    required this.id,
    required this.commandeId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.imageUrl,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> map, String documentId) {
    return Message(
      id: documentId,
      commandeId: map['commandeId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commandeId': commandeId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}