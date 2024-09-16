import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';

class MainScreen extends StatelessWidget {
  final _auth = FirebaseAuth.instance;

  MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    final String? displayName = user?.email?.split('@')[0];
    const String defaultPhotoURL =
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTOpAOxfF3g-Q1Q1BmzgYl2_pyqwvUjvVv_vg&s';
    final String photoURL = user?.photoURL ?? defaultPhotoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Screen'),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(40),
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              NetworkImage(photoURL ?? defaultPhotoURL),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Hi, $displayName!\nWelcome back to CodeHub',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
