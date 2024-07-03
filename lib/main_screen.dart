import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/messagerie.dart';
import 'package:smartboard/parametrer_compte.dart';

import 'package:smartboard/presence_page.dart';
import 'commande_passé_web.dart';
import 'home_page.dart';

import 'residences_page.dart';
import 'notifications_page.dart';
import 'personnel_page.dart';

class MainScreen extends StatefulWidget {
  final String entrepriseId;
  final String agentId;

  MainScreen({required this.entrepriseId, required this.agentId});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;
  List<Map<String, String>> _currentOrders = []; // Simulated list of orders

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      HomePage(entrepriseId: widget.entrepriseId),
      CommandePasseeWeb(entrepriseId: widget.entrepriseId),
      NotificationsPage(entrepriseId: widget.entrepriseId, clientId: ''),
      PersonnelPage(entrepriseId: widget.entrepriseId),
      PresencePage(entrepriseId: widget.entrepriseId),
      ResidencesPage(entrepriseId: widget.entrepriseId),
      ParametreCompte(entrepriseId: widget.entrepriseId),
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
      appBar: kIsWeb ? _buildWebAppBar() : _buildMobileAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: !kIsWeb
          ? BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(
            icon: PopupMenuButton<int>(
              icon: Icon(Icons.more_vert),
              onSelected: (int index) {
                switch (index) {
                  case 4:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ResidencesPage(entrepriseId: widget.entrepriseId)));
                    break;
                  case 5:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PresencePage(entrepriseId: widget.entrepriseId)));
                    break;
                  case 6:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MessageriePage(currentEntrepriseId: widget.entrepriseId, currentClientId: '')));
                    break;
                  case 7:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ParametreCompte(entrepriseId: widget.entrepriseId)));
                    break;
                  case 8:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PersonnelPage(entrepriseId: widget.entrepriseId)));
                    break;
                  default:
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                PopupMenuItem<int>(value: 4, child: Row(children: [Icon(Icons.apartment, color: Colors.grey), SizedBox(width: 10), Text('Résidences')])),
                PopupMenuItem<int>(value: 5, child: Row(children: [Icon(Icons.access_time, color: Colors.grey), SizedBox(width: 10), Text('Présence')])),
                PopupMenuItem<int>(value: 6, child: Row(children: [Icon(Icons.message, color: Colors.grey), SizedBox(width: 10), Text('Messagerie')])),
                PopupMenuItem<int>(value: 7, child: Row(children: [Icon(Icons.settings, color: Colors.grey), SizedBox(width: 10), Text('Paramètres')])),
                PopupMenuItem<int>(value: 8, child: Row(children: [Icon(Icons.group, color: Colors.grey), SizedBox(width: 10), Text('Personnel')])),
              ],
            ),
            label: 'Plus',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index < 3) _onItemTapped(index);
        },
      )
          : null,
    );
  }

  AppBar _buildWebAppBar() {
    return AppBar(
      automaticallyImplyLeading: false, // Remove the back button
      title: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 40),
          SizedBox(width: 10),
          Text('Smartboard'),
          Spacer(),
          if (_currentOrders.isNotEmpty)
            Text(
              'Commande en cours',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
        ],
      ),
      actions: <Widget>[
        _buildWebMenuButton('Home', Icons.home, 0),
        _buildWebMenuButton('Historique', Icons.history, 1),
        _buildWebMenuButton('Notifications', Icons.notifications, 2),
        _buildWebMenuButton('Personnel', Icons.group, 3),
        _buildWebMenuButton('Présence', Icons.access_time, 4),
        _buildWebMenuButton('Résidences', Icons.apartment, 5),
        _buildWebMenuButton('Paramètres', Icons.settings, 6),
      ],
    );
  }

  AppBar _buildMobileAppBar() {
    return AppBar(
      automaticallyImplyLeading: false, // Remove the back button
      title: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 40),
          SizedBox(width: 10),
          Text('Smartboard'),
          Spacer(),
          if (_currentOrders.isNotEmpty)
            Text(
              'Commande en cours',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
        ],
      ),
    );
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
}