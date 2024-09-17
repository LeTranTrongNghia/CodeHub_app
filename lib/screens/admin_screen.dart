// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'problems_screen.dart';

class AdminScreen extends StatelessWidget {
  final _auth = FirebaseAuth.instance;

  AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
      body: Center(
        child: Card(
          child: ListTile(
            title: const Text('Problems'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ProblemsScreen()),
              );
            },
          ),
        ),
      ),
    );
  }
}
