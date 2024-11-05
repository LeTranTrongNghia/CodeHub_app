// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/auth_screen.dart';
import 'package:provider/provider.dart';
import '../../controllers/language_controller.dart';

class MainScreen extends StatelessWidget {
  final _auth = FirebaseAuth.instance;

  MainScreen({super.key});

  late LanguageController _languageController;

  @override
  Widget build(BuildContext context) {
    _languageController = Provider.of<LanguageController>(context);
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
                          backgroundImage: NetworkImage(photoURL),
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<List<String>>(
                          future: Future.wait([
                            _languageController.translateText('hi'),
                            _languageController.translateText('welcome_back'),
                          ]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator(); // Show a loading indicator while fetching
                            }
                            if (snapshot.hasError) {
                              return Text(
                                  'Error: ${snapshot.error}'); // Handle error
                            }
                            final hiText = snapshot.data?[0] ?? 'Hi';
                            final welcomeBackText =
                                snapshot.data?[1] ?? 'Welcome back to CodeHub';
                            return Text(
                              '$hiText, $displayName!\n$welcomeBackText',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24),
                            );
                          },
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
