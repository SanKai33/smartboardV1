import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'models/message.dart';

class GroupMessagingPage extends StatefulWidget {
  final String commandeId;
  final String currentUserId;
  final String currentUserName;

  GroupMessagingPage({required this.commandeId, required this.currentUserId, required this.currentUserName});

  @override
  _GroupMessagingPageState createState() => _GroupMessagingPageState();
}

class _GroupMessagingPageState extends State<GroupMessagingPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  void _sendMessage({String imageUrl = ''}) async {
    if (_messageController.text.isNotEmpty || imageUrl.isNotEmpty) {
      Message message = Message(
        id: '',
        commandeId: widget.commandeId,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        text: _messageController.text,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('messages').add(message.toMap());
      _messageController.clear();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      String imageUrl = await _uploadImage(File(pickedFile.path));
      _sendMessage(imageUrl: imageUrl);
    }
  }

  Future<String> _uploadImage(File image) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child('messages').child(fileName);
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messagerie de Groupe'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('messages')
                  .where('commandeId', isEqualTo: widget.commandeId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Aucun message'));
                }

                List<DocumentSnapshot> docs = snapshot.data!.docs;
                List<Message> messages = docs.map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    Message message = messages[index];
                    return ListTile(
                      leading: message.imageUrl.isNotEmpty
                          ? Image.network(message.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                          : null,
                      title: Text(message.senderName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.text.isNotEmpty) Text(message.text),
                          Text(DateFormat('dd MMM kk:mm').format(message.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
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
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Entrez un message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}