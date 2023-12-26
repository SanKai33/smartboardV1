import 'package:flutter/material.dart';




class MessageriePage extends StatefulWidget {
  @override
  _MessageriePageState createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  List<String> messages = [];
  final TextEditingController messageController = TextEditingController();

  void sendMessage() {
    setState(() {
      messages.add(messageController.text);
      messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messagerie'),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.3,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(messages[index]),
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
          ),
          Center(
            child: Text(
              'La messagerie sera disponible dans la prochaine mise à jour.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}