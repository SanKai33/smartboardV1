

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages avec ${widget.agentName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('receiverId', isEqualTo: widget.agentId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('Aucun message disponible.'),
                  );
                }

                List<Message> messages = snapshot.data!.docs
                    .map((doc) => Message.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    return GestureDetector(
                      onLongPress: () => deleteMessage(message.id),
                      child: ListTile(
                        title: Text(message.text),
                        subtitle: Text(
                          'De: ${message.senderName} - ${message.timestamp.toDate().toString()}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Tapez votre message ici',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}