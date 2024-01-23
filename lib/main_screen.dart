import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/presence_page.dart';
import 'home_page.dart';
import 'calendar_page.dart';
import 'residences_page.dart';
import 'notifications_page.dart';
import 'personnel_page.dart';

class MainScreen extends StatefulWidget {
  final String entrepriseId;

  MainScreen({required this.entrepriseId, required String agentId});

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
      ResidencesPage(entrepriseId: widget.entrepriseId),
      NotificationsPage(entrepriseId: widget.entrepriseId),
      PersonnelPage(entrepriseId: widget.entrepriseId),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PresencePage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildWebMenuButton(String title, IconData icon, int index) {
    return TextButton(
      onPressed: () => _onItemTapped(index),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18),
          SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }

  AppBar _buildWebAppBar() {
    return AppBar(
      title: Text('Acceuil'),
      actions: <Widget>[
        _buildWebMenuButton('Accueil', Icons.home, 0),
        _buildWebMenuButton('Calendrier', Icons.calendar_today, 1),
        _buildWebMenuButton('Résidences', Icons.apartment, 2),
        _buildWebMenuButton('Notifications', Icons.notifications, 3),
        _buildWebMenuButton('Personnel', Icons.person, 4),
        IconButton(
          icon: Icon(Icons.qr_code),
          onPressed: () => _onItemTapped(5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? _buildWebAppBar() : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: !kIsWeb ? BottomNavigationBar(
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
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'Présence',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ) : null,
    );
  }
}