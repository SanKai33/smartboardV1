import 'package:flutter/foundation.dart';
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
      ResidencesPage(entrepriseId: widget.entrepriseId),
      NotificationsPage(entrepriseId:widget.entrepriseId),
      PersonnelPage(entrepriseId: widget.entrepriseId,),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (kIsWeb) {
        Navigator.of(context).pop(); // Ferme le menu Drawer sur PC après la sélection
      }
    });
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Accueil'),
            onTap: () => _onItemTapped(0),
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Calendrier'),
            onTap: () => _onItemTapped(1),
          ),
          ListTile(
            leading: Icon(Icons.apartment),
            title: Text('Résidences'),
            onTap: () => _onItemTapped(2),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () => _onItemTapped(3),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Personnel'),
            onTap: () => _onItemTapped(4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? AppBar(
        title: Text('Votre Application'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ) : null,
      drawer: kIsWeb ? _buildDrawer() : null,
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
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ) : null,
    );
  }
}