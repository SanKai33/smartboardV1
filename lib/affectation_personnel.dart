import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/personnel.dart';





void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Affectation du Personnel',
      home: AffectationPage(),
    );
  }
}

class AffectationPage extends StatefulWidget {
  @override
  _AffectationPageState createState() => _AffectationPageState();
}

class _AffectationPageState extends State<AffectationPage> {
  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Affectation du Personnel'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(selectedDate == null ? 'Sélectionner une date' : 'Date: ${selectedDate!.toLocal()}'.split(' ')[0]),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Personnel Disponible', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('personnel').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    Personnel personnel = Personnel.fromFirestore(snapshot.data!.docs[index]);
                    return Draggable<Personnel>(
                      data: personnel,
                      child: PersonnelCard(personnel: personnel),
                      feedback: Material(
                        child: PersonnelCard(personnel: personnel),
                      ),
                      childWhenDragging: Container(),
                    );
                  },
                );
              },
            ),
          ),
          if (selectedDate != null) ...[
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('commandes')
                    .where('date', isEqualTo: selectedDate!.toIso8601String())
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text('Chargement des commandes...');

                  return ListView(
                    children: snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                      return CommandeItem(
                        commandeId: document.id,
                        commandeData: data,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PersonnelCard extends StatelessWidget {
  final Personnel personnel;

  PersonnelCard({required this.personnel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(4.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${personnel.nom}', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(personnel.prenom),
          ],
        ),
      ),
    );
  }
}

class CommandeItem extends StatelessWidget {
  final String commandeId;
  final Map<String, dynamic> commandeData;

  CommandeItem({required this.commandeId, required this.commandeData});

  @override
  Widget build(BuildContext context) {
    return DragTarget<Personnel>(
      onWillAccept: (personnel) => true,
      onAccept: (Personnel personnel) {
        // Mettre à jour la commande dans Firestore avec l'ID du personnel affecté
        FirebaseFirestore.instance.collection('commandes').doc(commandeId).update({
          'personnelId': personnel.id,
        }).then((value) {
          print("Commande $commandeId mise à jour avec le personnel ${personnel.nom}");
        }).catchError((error) {
          print("Erreur lors de la mise à jour de la commande: $error");
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Card(
            elevation: 4.0,
            child: ListTile(
              leading: Icon(Icons.assignment, color: Colors.blue),
              title: Text(commandeData['description'] ?? 'Commande', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Commande ID: $commandeId'),
              trailing: Icon(Icons.drag_handle, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}