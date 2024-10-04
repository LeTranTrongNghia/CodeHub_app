// ignore_for_file: depend_on_referenced_packages, prefer_const_constructors_in_immutables, use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, prefer_const_constructors, unnecessary_brace_in_string_interps, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class QuestionScreen extends StatefulWidget {
  final String courseTitle;
  final String lectureTitle;

  QuestionScreen({required this.courseTitle, required this.lectureTitle});

  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  String rawResponse = ''; // Variable to hold the raw API response
  bool showModal = false; // Control visibility of the modal
  String question = ''; // Variable to hold the question
  List<String> options = []; // List to hold answer options
  String selectedOption = ''; // Variable to hold the selected option
  bool isCorrect = false; // Variable to hold the correctness of the answer

  @override
  void initState() {
    super.initState();
  }

  Future<void> _generateQuestions() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${dotenv.env['VITE_API_GENERATIVE_LANGUAGE_CLIENT']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Generate 1 multiple-choice question related to the course "${widget.courseTitle}" and the lecture "${widget.lectureTitle}". Each question should have one correct answer and three distractors. Do not generate blank line and ** symbol. This is the example of the format: Which of the following is NOT a valid data type in C programming language?\n(A) int\n(B) float\n(C) char\n(D) boolean'
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        rawResponse = jsonDecode(response.body)['candidates'][0]['content']
                ['parts'][0]['text']
            .trim();
        print("Raw API response: $rawResponse"); // Print the raw response

        // Parse the question and options
        _parseResponse(rawResponse);

        setState(() {
          showModal = true; // Show modal after questions are generated
        });
      } else {
        print('Error: ${response.statusCode}'); // Handle non-200 responses
      }
    } catch (error) {
      print('Error while generating questions: $error');
    }
  }

  Future<void> _checkAnswer(String option) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${dotenv.env['VITE_API_GENERATIVE_LANGUAGE_CLIENT']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Given the question: "${question}" and the selected answer: "${option}", respond with true or false only.'
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        rawResponse = jsonDecode(response.body)['candidates'][0]['content']
                ['parts'][0]['text']
            .trim();
        print("Raw API response: $rawResponse");

        // Update isCorrect based on rawResponse
        isCorrect = (rawResponse.toLowerCase() == 'true');
        selectedOption = option; // Set the selected option
        setState(() {}); // Trigger a rebuild to update UI
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      print('Error while checking answer: $error');
    }
  }

  void _parseResponse(String response) {
    // Split the response into question and options, filtering out empty lines
    final parts =
        response.split('\n').where((line) => line.trim().isNotEmpty).toList();
    question = parts[0]; // First line is the question
    options = parts
        .sublist(1)
        .map((option) => option.trim())
        .toList(); // Remaining lines are options
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Questions')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              rawResponse = ''; // Clear previous response
              question = ''; // Clear previous question
              options.clear(); // Clear previous options
              _generateQuestions(); // Call to generate new questions
            });
          },
          child: Text('Start Quiz'),
        ),
      ),
      floatingActionButton: showModal
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  showModal = false; // Close modal
                });
              },
              child: Icon(Icons.close),
            )
          : null,
      // Modal for displaying the question and options
      bottomSheet: showModal
          ? Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  // Allow scrolling if content is long
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        question,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center, // Center the text
                      ),
                      SizedBox(height: 20),
                      if (options.isNotEmpty) // Check if options are available
                        ...options.map((option) {
                          bool isSelected = selectedOption == option;
                          Color cardColor = isSelected
                              ? (isCorrect ? Colors.green : Colors.red)
                              : Colors.grey[200]!;

                          return GestureDetector(
                            onTap: () {
                              _checkAnswer(option); // Check the answer
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width -
                                  16, // Full width minus horizontal margins
                              margin: EdgeInsets.symmetric(
                                  vertical: 8.0), // Only vertical margin
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Text(
                                option,
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          );
                        }).toList(),
                      // Show next question button if the answer is correct
                      if (isCorrect && selectedOption.isNotEmpty)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              rawResponse = ''; // Clear previous response
                              question = ''; // Clear previous question
                              options.clear(); // Clear previous options
                              _generateQuestions(); // Call to generate new questions
                            });
                          },
                          child: Text('Next Question'),
                        ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
