import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';
import 'registrer_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController smsCodeController = TextEditingController();

  String? verificationId;
  bool isLoading = false;

  Future<void> _sendCode(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen(entrepriseId: '',)),
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        _showSnackBar(context, "Erreur d'authentification: ${e.message}");
        setState(() {
          isLoading = false;
        });
      },
      codeSent: (String verId, int? resendToken) {
        verificationId = verId;
        setState(() {
          isLoading = false;
        });
        _showSnackBar(context, "Code de vérification envoyé");
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  Future<void> _signInWithPhoneNumber(BuildContext context) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: smsCodeController.text,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen(entrepriseId: '',)),
      );
    } catch (e) {
      _showSnackBar(context, "Erreur lors de la connexion: ${e.toString()}");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion par téléphone'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Numéro de téléphone'),
                keyboardType: TextInputType.phone,
              ),
              ElevatedButton(
                onPressed: () => _sendCode(context),
                child: Text('Envoyer le code de vérification'),
              ),
              TextField(
                controller: smsCodeController,
                decoration: InputDecoration(labelText: 'Code de vérification SMS'),
                keyboardType: TextInputType.number,
              ),
              ElevatedButton(
                onPressed: () => _signInWithPhoneNumber(context),
                child: Text('Se connecter'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                },
                child: Text('Inscription'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}