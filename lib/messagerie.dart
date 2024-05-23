import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'message_tap.dart';
import 'models/personnel.dart';


class MessageriePage extends StatefulWidget {
  final String currentEntrepriseId;

  MessageriePage({required this.currentEntrepriseId});

  @override
  _MessageriePageState createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messagerie'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher par nom ou prénom',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('personnel')
                  .where('entrepriseId', isEqualTo: widget.currentEntrepriseId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<Personnel> personnelList = snapshot.data!.docs
                    .map((doc) => Personnel.fromFirestore(doc))
                    .where((personnel) =>
                personnel.nom.toLowerCase().contains(searchQuery) ||
                    personnel.prenom.toLowerCase().contains(searchQuery))
                    .toList();

                return ListView.builder(
                  itemCount: personnelList.length,
                  itemBuilder: (context, index) {
                    Personnel personnel = personnelList[index];
                    return Card(
                      margin: EdgeInsets.all(10.0),
                      child: ListTile(
                        title: Text('${personnel.nom} ${personnel.prenom}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageTapPage(
                                agentId: personnel.id,
                                agentName: '${personnel.nom} ${personnel.prenom}', senderId: '', senderName: '',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}