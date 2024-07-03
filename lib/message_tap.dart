

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models/message.dart';

class MessageTapPage extends StatefulWidget {
  final String agentId;
  final String agentName;
  final String senderId;  // ID de l'expéditeur (utilisateur actuel)
  final String senderName;  // Nom de l'expéditeur (utilisateur actuel)

  MessageTapPage({
    required this.agentId,
    required this.agentName,
    required this.senderId,
    required this.senderName,
  });

  @override
  _MessageTapPageState createState() => _MessageTapPageState();
}

class _MessageTapPageState extends State<MessageTapPage> {
  final TextEditingController messageController = TextEditingController();

  void sendMessage() {
    if (messageController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('messages').add({
        'senderId': widget.senderId,
        'senderName': widget.senderName,
        'receiverId': widget.agentId,
        'receiverName': widget.agentName,
        'text': messageController.text,
        'timestamp': Timestamp.now(),
      });
      messageController.clear();
    }
  }

  void deleteMessage(String messageId) {
    FirebaseFirestore.instance.collection('messages').doc(messageId).delete();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

