import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'historique_commande_page.dart';
import 'models/commande.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Nombre d'onglets
      child: Scaffold(
        appBar: AppBar(
          title: Text('Calendrier'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Commandes'),
              Tab(text: 'Disponibilité'),
            ],
          ),
        ),
        body: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2010, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
            Expanded(
              child: TabBarView(
                children: [
                  CommandesWidget(selectedDay: _selectedDay), // Widget pour les commandes
                  DisponibilitesWidget(selectedDay: _selectedDay), // Widget pour les disponibilités
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommandesWidget extends StatelessWidget {
  final DateTime? selectedDay;

  CommandesWidget({this.selectedDay});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Commande>>(
      stream: getCommandesForDate(selectedDay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("Aucune commande pour cette date"));
        }

        List<Commande> commandes = snapshot.data!;
        return ListView.builder(
          itemCount: commandes.length,
          itemBuilder: (context, index) {
            Commande commande = commandes[index];
            return Card(
              child: ListTile(
                title: Text(commande.nomResidence),
                subtitle: Text("Commande ID: ${commande.id}"),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HistoriqueCommandePage(commande: commande),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Stream<List<Commande>> getCommandesForDate(DateTime? date) {
    if (date == null) {
      return Stream.value([]);
    }

    DateTime startDate = DateTime(date.year, date.month, date.day);
    DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('commandes')
        .where('dateCommande', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('dateCommande', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Commande.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}

class DisponibilitesWidget extends StatelessWidget {
  final DateTime? selectedDay;

  DisponibilitesWidget({this.selectedDay});

  @override
  Widget build(BuildContext context) {
    // Ici, insérez la logique et l'interface utilisateur pour afficher les disponibilités pour la date sélectionnée
    return Center(
      child: Text(selectedDay != null ? 'Disponibilités pour ${selectedDay!.toLocal()}' : 'Sélectionnez une date'),
    );
  }
}