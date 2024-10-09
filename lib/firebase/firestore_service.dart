import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserFields() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      // Define the new fields
      final Map<String, dynamic> newFields = {
        'solvedProblems': [], // Initialize as an empty array
        'recentSolved': '', // Initialize as an empty string
      };

      // Update the user document
      await _firestore.collection('users').doc(user.uid).update(newFields);
    }
  }
}
