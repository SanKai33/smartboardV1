import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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
    // Ici, insérez la logique et l'interface utilisateur pour afficher les commandes pour la date sélectionnée
    return Center(
      child: Text(selectedDay != null ? 'Commandes pour ${selectedDay!.toLocal()}' : 'Sélectionnez une date'),
    );
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