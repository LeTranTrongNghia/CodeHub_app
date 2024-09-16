import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';

class AdminScreen extends StatelessWidget {
  final _auth = FirebaseAuth.instance;

  AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              _auth.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome, Admin!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
