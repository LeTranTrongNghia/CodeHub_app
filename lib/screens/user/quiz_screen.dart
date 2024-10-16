// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_screen.dart'; // Import the QuestionScreen

class QuizScreen extends StatelessWidget {
  final String courseId;

  QuizScreen({required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Quiz practice'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Course not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['title']; // Get course title
          final lectures = data['lectures'] as List<dynamic>; // Get lectures

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: lectures.length,
                    itemBuilder: (context, index) {
                      final lecture = lectures[index];
                      return ListTile(
                        title: Text(lecture['title_lecture']!),
                        subtitle: Text(lecture['time']!),
                        onTap: () {
                          // Navigate to QuestionScreen when a lecture is selected
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionScreen(
                                courseTitle: title,
                                lectureTitle: lecture['title_lecture']!,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
