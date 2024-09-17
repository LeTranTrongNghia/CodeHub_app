// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_screen.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String email = '';
  String password = '';
  String confirmPassword = '';
  String username = '';
  bool isLogin = true;

  void _submitAuthForm() async {
    UserCredential userCredential;
    try {
      if (isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (userCredential.user != null && userCredential.user!.emailVerified) {
          final userDoc = await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
          final userData = userDoc.data() as Map<String, dynamic>;
          final userRole = userData['role'];

          if (userRole == 'admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => AdminScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please verify your email first.')),
          );
        }
      } else {
        if (password != confirmPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match.')),
          );
          return;
        }

        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user!.sendEmailVerification();

        // Store user information in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'username': username,
          'email': email,
          'password': password,
          'avatar': '',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'role': 'user',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Verification email sent. Please check your inbox.')),
        );
      }
    } catch (e, stacktrace) {
      print('Error: $e');
      print('Stacktrace: $stacktrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void _resetPassword() async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email.')),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Password reset email sent. Please check your inbox.')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isLogin)
              TextField(
                decoration: const InputDecoration(labelText: 'Username'),
                onChanged: (value) {
                  setState(() {
                    username = value;
                  });
                },
              ),
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              onChanged: (value) {
                setState(() {
                  email = value;
                });
              },
            ),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onChanged: (value) {
                setState(() {
                  password = value;
                });
              },
            ),
            if (!isLogin)
              TextField(
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
                onChanged: (value) {
                  setState(() {
                    confirmPassword = value;
                  });
                },
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitAuthForm,
              child: Text(isLogin ? 'Login' : 'Sign Up'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(
                  isLogin ? 'Create new account' : 'I already have an account'),
            ),
            if (isLogin)
              TextButton(
                onPressed: _resetPassword,
                child: const Text('Forgot Password?'),
              ),
          ],
        ),
      ),
    );
  }
}
