import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/appAgent/parametrer_commpte_agent.dart';
import 'package:smartboard/appAgent/presence_page_agent.dart';
import '../calendar_page.dart';
import '../messagerie.dart';
import '../notifications_page.dart';
import 'home_page_agent.dart';

class MainScreenAgent extends StatefulWidget {
  final String entrepriseId;
  final String agentId;
  final String clientId;

  MainScreenAgent({required this.entrepriseId, required this.agentId, required this.clientId});

  @override
  _MainScreenAgentState createState() => _MainScreenAgentState();
}

class _MainScreenAgentState extends State<MainScreenAgent> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      HomePageAgent(entrepriseId: widget.entrepriseId, agentId: widget.agentId),
      CalendarPage(),
      NotificationsPage(entrepriseId: widget.entrepriseId, clientId: widget.clientId),
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
                  case 6:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MessageriePage(currentEntrepriseId: widget.entrepriseId, currentClientId: '',)));
                    break;
                  case 7:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ParametreCompteAgent(agentId: widget.agentId)));
                    break;
                  default:
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                PopupMenuItem<int>(value: 6, child: Row(children: [Icon(Icons.message, color: Colors.grey), SizedBox(width: 10), Text('Messagerie')])),
                PopupMenuItem<int>(value: 7, child: Row(children: [Icon(Icons.settings, color: Colors.grey), SizedBox(width: 10), Text('Paramètres')])),
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
      title: Text('Smartboard'),
      actions: <Widget>[
        _buildWebMenuButton('Home', Icons.home, 0),
        _buildWebMenuButton('Calendar', Icons.calendar_today, 1),
        _buildWebMenuButton('Notifications', Icons.notifications, 2),
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