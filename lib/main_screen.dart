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
      appBar: _buildWebAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      drawer: _buildWebDrawer(),
    );
  }

  AppBar _buildWebAppBar() {
    return AppBar(
      automaticallyImplyLeading: false, // Remove the back button
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Ajoute un défilement horizontal
        child: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 40),
            SizedBox(width: 10),
            Text('Smartboard'),
            SizedBox(width: 20), // Espacement supplémentaire pour les petits écrans
            if (_currentOrders.isNotEmpty)
              Text(
                'Commande en cours',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
          ],
        ),
      ),
      actions: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Rendre les actions défilantes
          child: Row(
            children: [
              _buildWebMenuButton('Home', Icons.home, 0),
              _buildWebMenuButton('Historique', Icons.history, 1),
              _buildWebMenuButton('Notifications', Icons.notifications, 2),
              _buildWebMenuButton('Personnel', Icons.group, 3),
              _buildWebMenuButton('Présence', Icons.access_time, 4),
              _buildWebMenuButton('Résidences', Icons.apartment, 5),
              _buildWebMenuButton('Paramètres', Icons.settings, 6),
            ],
          ),
        ),
      ],
    );
  }

  Drawer _buildWebDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Smartboard', style: TextStyle(color: Colors.white)),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          _buildDrawerItem('Home', Icons.home, 0),
          _buildDrawerItem('Historique', Icons.history, 1),
          _buildDrawerItem('Notifications', Icons.notifications, 2),
          _buildDrawerItem('Personnel', Icons.group, 3),
          _buildDrawerItem('Présence', Icons.access_time, 4),
          _buildDrawerItem('Résidences', Icons.apartment, 5),
          _buildDrawerItem('Paramètres', Icons.settings, 6),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(String title, IconData icon, int index) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      onTap: () {
        _onItemTapped(index);
        Navigator.of(context).pop(); // Close the drawer
      },
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