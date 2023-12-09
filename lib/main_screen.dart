import 'package:flutter/material.dart';
import 'home_page.dart';
import 'calendar_page.dart';
import 'residences_page.dart';
import 'notifications_page.dart';
import 'personnel_page.dart';

class MainScreen extends StatefulWidget {
  final String entrepriseId;

  MainScreen({required this.entrepriseId});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      HomePage(entrepriseId: widget.entrepriseId),
      CalendarPage(),
      ResidencesPage(entrepriseId: widget.entrepriseId), // Utilisation de l'entrepriseId du widget MainScreen
      NotificationsPage(),
      PersonnelPage(entrepriseId: widget.entrepriseId,),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendrier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment),
            label: 'Résidences',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Personnel',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        // Utilisez la couleur que vous préférez
        onTap: _onItemTapped,
      ),
    );
  }
}