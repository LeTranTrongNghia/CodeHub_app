// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors, unused_local_variable

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_screen.dart';
import 'home_screen.dart';
import 'problems_screen.dart';
import 'course_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 3;

  String photoURLValue = ''; // Define the photoURLValue variable

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ProblemsScreen()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => CourseScreen()),
        );
        break;
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
    }
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  void _showEditForm(BuildContext context, Map<String, dynamic> userData) {
    final _usernameController =
        TextEditingController(text: userData['username']);
    final _emailController = TextEditingController(text: userData['email']);
    final _roleController = TextEditingController(text: userData['role']);
    final _avatarController = TextEditingController(text: userData['avatar']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                TextField(
                  controller: _avatarController,
                  decoration: const InputDecoration(labelText: 'Avatar URL'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final User? user = _auth.currentUser;
                if (user != null) {
                  await _firestore.collection('users').doc(user.uid).update({
                    'username': _usernameController.text,
                    'email': _emailController.text,
                    'role': _roleController.text,
                    'avatar': _avatarController.text,
                    'updated_at': FieldValue.serverTimestamp(),
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Screen'),
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred.'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No user data found.'));
          }

          final userData = snapshot.data!;
          final String displayName = userData['username'] ?? 'User';
          final String photoURLValueValue = userData['avatar']?.isNotEmpty ==
                  true
              ? userData['avatar']
              : 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTOpAOxfF3g-Q1Q1BmzgYl2_pyqwvUjvVv_vg&s';

          return Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(40),
              child: SizedBox(
                height: 320, // Adjusted height to prevent overflow
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      Center(
                        // Center the content
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(userData['avatar']
                                          ?.isNotEmpty ==
                                      true
                                  ? userData['avatar']
                                  : 'https://example.com/fallback_image.png'), // Fallback image if avatar is empty
                              onBackgroundImageError: (error, stackTrace) {
                                // Handle image loading error
                                setState(() {
                                  // Set a fallback image or handle the error
                                  photoURLValue =
                                      'https://example.com/fallback_image.png'; // Replace with your fallback image URL
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Hi, $displayName!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Email: ${userData['email']}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Role: ${userData['role']}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditForm(context, userData),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment, color: Colors.black),
            label: 'Problems',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book, color: Colors.black),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
