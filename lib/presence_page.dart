import 'package:flutter/material.dart';

class PresencePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Présence'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Page de Présence',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Ici, vous pouvez ajouter d'autres widgets selon vos besoins.
            // Par exemple, un widget pour scanner un QR code, afficher des informations, etc.
          ],
        ),
      ),
    );
  }
}