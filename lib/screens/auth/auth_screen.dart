// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print, prefer_const_constructors, unused_import, use_rethrow_when_possible

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:forui/forui.dart'; // Updated import
import '../admin/admin_screen.dart';
import '../user/home_screen.dart';
import '../../firebase/firestore_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (userCredential.user != null && userCredential.user!.emailVerified) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
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
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
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

        // Call the Firestore service to update user fields
        await FirestoreService().updateUserFields();

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

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Check if the user is null (sign-in was canceled)
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was canceled.')),
        );
        return; // Exit the method if sign-in was canceled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Retry mechanism for fetching user data
      await _fetchUserDataWithRetry(userCredential.user!.uid);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      print('Google Sign-In Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during Google sign-in: $e')),
      );
    }
  }

  Future<void> _fetchUserDataWithRetry(String userId) async {
    int attempts = 0;
    const int maxAttempts = 5;
    const Duration delay = Duration(seconds: 2);

    while (attempts < maxAttempts) {
      try {
        // Store user information in Firestore
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          // Process user data if needed
          break; // Exit loop if successful
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          throw e; // Rethrow the error if max attempts reached
        }
        await Future.delayed(delay * attempts); // Exponential backoff
      }
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
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: FCard(
                title: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: const Center(child: Text('Login')),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0), // Inner padding
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Minimize height
                    children: [
                      const SizedBox(height: 20),
                      FTextField.email(
                        controller: _emailController, // TextEditingController
                        hint: 'john@doe.com',
                      ),
                      const SizedBox(height: 16),
                      FTextField.password(
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 30),
                      FButton(
                        prefix: FButtonIcon(icon: FAssets.icons.logIn),
                        label: Text(isLogin ? 'Sign In' : 'Sign Up'),
                        onPress: _submitAuthForm,
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          setState(() {
                            isLogin = !isLogin;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                isLogin
                                    ? 'Create new account'
                                    : 'I already have an account',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: _signInWithGoogle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.mail, color: Colors.black),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text('Login with Google',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isLogin)
                        // Update Forgot Password button with InkWell and Row
                        InkWell(
                          onTap: _resetPassword,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lock,
                                  color:
                                      Colors.black), // Use an appropriate icon
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
