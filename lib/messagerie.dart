import 'package:flutter/material.dart';

class MessageriePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messagerie'),
      ),
      body: Center(
        child: Text('Bienvenue dans votre messagerie'),
      ),
    );
  }
}