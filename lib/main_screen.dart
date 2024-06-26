import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/messagerie.dart';
import 'package:smartboard/parametrer_compte.dart';
import 'package:smartboard/presence_page.dart';
import 'package:smartboard/tarrification_page.dart';
import 'home_page.dart';
import 'calendar_page.dart';
import 'residences_page.dart';
import 'notifications_page.dart';
import 'personnel_page.dart';

class MainScreen extends StatefulWidget {
  final String entrepriseId;
  final String agentId;

  MainScreen({required this.entrepriseId, required this.agentId, });

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
      NotificationsPage(entrepriseId: widget.entrepriseId),
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
      appBar: kIsWeb ? _buildWebAppBar() : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: !kIsWeb ? BottomNavigationBar(
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MessageriePage(currentEntrepriseId: widget.entrepriseId,)));
                    break;
                  case 7:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ParametreCompte(entrepriseId: widget.entrepriseId)));
                    break;
                  case 8:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PersonnelPage(entrepriseId: widget.entrepriseId)));
                    break;
                  case 9:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => TarificationPage(entrepriseId: widget.entrepriseId,)));
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
                PopupMenuItem<int>(value: 9, child: Row(children: [Icon(Icons.local_atm, color: Colors.grey), SizedBox(width: 10), Text('Tarif')]))
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
      ) : null,
    );
  }

  AppBar _buildWebAppBar() {
    return AppBar(
      title: Text('Smartboard'),
      actions: <Widget>[
        _buildWebMenuButton('Home', Icons.home, 0),
        _buildWebMenuButton('Calendar', Icons.calendar_today, 1),
        _buildWebMenuButton('Notifications', Icons.notifications, 2),
        IconButton(icon: Icon(Icons.qr_code), onPressed: () => _onItemTapped(5)),
      ],
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



