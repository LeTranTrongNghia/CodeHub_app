// ignore_for_file: unused_import

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase/firebase_options.dart';
import 'screens/auth/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
