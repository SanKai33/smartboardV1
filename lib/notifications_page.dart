import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  final String entrepriseId;

  NotificationsPage({required this.entrepriseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('entrepriseId', isEqualTo: entrepriseId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur lors du chargement des notifications'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune notification.'));
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text(data['titre']),
                  subtitle: Text(data['message']),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // Logique de navigation ou d'action lorsque l'utilisateur appuie sur une notification
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
