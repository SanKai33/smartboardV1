import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'historique_présence.dart';
import 'models/personnel.dart';
import 'models/presence.dart';
import 'models/residence.dart';



class PresencePage extends StatefulWidget {
  final String entrepriseId;

  PresencePage({required this.entrepriseId});

  @override
  _PresencePageState createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _presenceStatus = {};

  @override
  void initState() {
    super.initState();
    _loadPresence();
    _schedulePresenceArchiving();
  }

  Future<void> _loadPresence() async {
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    var snapshot = await _firestore.collection('fichesPresence')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var fichePresence = FichePresence.fromFirestore(snapshot.docs.first);

      setState(() {
        _presenceStatus = fichePresence.statutPresence;
      });
    } else {
      setState(() {
        _presenceStatus = {};
      });
    }
  }

  Future<void> _schedulePresenceArchiving() async {
    DateTime now = DateTime.now();
    DateTime midnight = DateTime(now.year, now.month, now.day + 1);

    Duration untilMidnight = midnight.difference(now);

    Future.delayed(untilMidnight, () async {
      await _archivePresence();
      _resetPresenceStatus();
      _schedulePresenceArchiving(); // Schedule the next archive
    });
  }

  Future<void> _archivePresence() async {
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    var snapshot = await _firestore.collection('fichesPresence')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var fichePresence = FichePresence.fromFirestore(snapshot.docs.first);
      await _firestore.collection('historiquePresence').add(fichePresence.toMap());
    }
  }

  Future<void> _resetPresenceStatus() async {
    var personnelsSnapshot = await _firestore.collection('personnel')
        .where('entrepriseId', isEqualTo: widget.entrepriseId)
        .get();

    for (var doc in personnelsSnapshot.docs) {
      var personnel = Personnel.fromFirestore(doc);
      personnel = personnel.copyWith(statutPresence: 'non présent');
      await _firestore.collection('personnel').doc(personnel.id).update(personnel.toMap());
    }
  }

  void _validatePresence(String personnelId, bool isPresent) async {
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    var snapshot = await _firestore.collection('fichesPresence')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    var personnelDoc = await _firestore.collection('personnel').doc(personnelId).get();
    var personnel = Personnel.fromFirestore(personnelDoc);

    if (snapshot.docs.isNotEmpty) {
      var docId = snapshot.docs.first.id;
      var fichePresence = FichePresence.fromFirestore(snapshot.docs.first);

      fichePresence.statutPresence[personnelId] = isPresent;
      personnel = personnel.copyWith(statutPresence: isPresent ? 'présent' : 'non présent');

      await _firestore.collection('fichesPresence').doc(docId).update(fichePresence.toMap());
    } else {
      var newFichePresence = FichePresence(
        id: '',
        date: _selectedDate,
        statutPresence: {personnelId: isPresent},
      );

      await _firestore.collection('fichesPresence').add(newFichePresence.toMap());
      personnel = personnel.copyWith(statutPresence: isPresent ? 'présent' : 'non présent');
    }

    await _firestore.collection('personnel').doc(personnel.id).update(personnel.toMap());

    setState(() {
      _presenceStatus[personnelId] = isPresent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche de Présence - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoriquePresencePage(entrepriseId: widget.entrepriseId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Nombre de présents : ${_presenceStatus.values.where((status) => status).length}'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('residences')
                  .where('entrepriseId', isEqualTo: widget.entrepriseId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      return _buildResidenceCard(Residence.fromFirestore(doc));
                    }).toList(),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenceCard(Residence residence) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('personnel')
          .where('residenceAffectee', isEqualTo: residence.id)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Erreur de chargement');
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 4.0,
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(residence.nom, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Aucun agent affecté'),
            ),
          );
        } else {
          int nbAgents = snapshot.data!.docs.length;
          int nbPresents = snapshot.data!.docs.where((doc) {
            String personnelId = doc.id;
            return _presenceStatus[personnelId] == true;
          }).length;

          return Card(
            elevation: 4.0,
            margin: EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  title: Text(residence.nom, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Agents affectés: $nbAgents\nPrésents: $nbPresents'),
                ),
                Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var personnelDoc = snapshot.data!.docs[index];
                    var personnel = Personnel.fromFirestore(personnelDoc);

                    return Card(
                      color: Colors.white,
                      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        title: Text('${personnel.nom} ${personnel.prenom}', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Téléphone : ${personnel.telephone}'),
                        trailing: Checkbox(
                          value: _presenceStatus[personnel.id] ?? false,
                          onChanged: (value) {
                            _validatePresence(personnel.id, value!);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }
}