// ignore_for_file: use_super_parameters, prefer_const_constructors, unused_import, must_be_immutable, depend_on_referenced_packages, implementation_imports, constant_identifier_names, prefer_const_constructors_in_immutables, library_private_types_in_public_api, use_build_context_synchronously, avoid_print, unused_element, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, duplicate_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/src/mode.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const LANGUAGE_VERSIONS = {
  'java': '15.0.2',
  'javascript': '18.15.0',
  'python': '3.10.0',
  'php': '8.2.3',
  'typescript': '5.0.3',
};

class SolveScreen extends StatefulWidget {
  final DocumentSnapshot problem;

  SolveScreen({Key? key, required this.problem}) : super(key: key);

  @override
  _SolveScreenState createState() => _SolveScreenState();
}

class _SolveScreenState extends State<SolveScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize FirebaseAuth
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Initialize Firestore

  String selectedLanguage = 'python'; // Default language
  String code = ''; // Code input by the user
  String result = ''; // Result from the API
  late CodeController controller;
  bool isSubmitEnabled = false; // Track if submit button should be enabled
  double correctnessRating = 0;
  double performanceRating = 0;
  double clarityRating = 0;

  bool isChatOpen = false; // Track if chat is open
  String chatInput = ''; // Input for chat
  List<String> chatHistory = []; // Store chat history

  @override
  void initState() {
    super.initState();
    controller = CodeController(
      text: '...', // Initial code
      language: python, // Default language
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.problem['title']),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: isSubmitEnabled
                ? _showSubmitDialog
                : null, // Show dialog if enabled
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          setState(() {
            isChatOpen = !isChatOpen; // Toggle chat visibility
          });
        },
        child: Icon(Icons.chat),
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title: ${widget.problem['title']}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Type: ${widget.problem['type']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Difficulty: ${widget.problem['difficulty']}',
                    style: TextStyle(
                      fontSize: 18,
                      color: _getDifficultyColor(widget.problem['difficulty']),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Statement:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.problem['statement'] ?? 'No statement available'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Divider(),
                  SizedBox(height: 10),
                  Text(
                    'Constraints:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ..._buildConstraints(widget.problem['constraints']),
                  SizedBox(height: 10),
                  Divider(),
                  Text(
                    'Test Cases:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ..._buildTestCases(widget.problem['testCases']),
                  Divider(),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // Aligns items
                    children: [
                      DropdownButton<String>(
                        dropdownColor: Colors.white,
                        value: selectedLanguage,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedLanguage = newValue;
                              controller.language = _getLanguageMode(
                                  newValue); // Update language in controller
                            });
                          }
                        },
                        items: <String>[
                          'java',
                          'javascript',
                          'python',
                          'php',
                          'typescript'
                        ].map<DropdownMenuItem<String>>((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _runCode(); // Call the function to run the code
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // Background color
                          foregroundColor: Colors.white, // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(4), // Corner radius
                          ),
                        ),
                        child: Text('Run'),
                      ),
                    ],
                  ),
                  CodeTheme(
                    data: CodeThemeData(
                        styles: monokaiSublimeTheme), // Apply the theme
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight:
                            300, // Set a maximum height to prevent overflow
                      ),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: controller, // Use the controller
                          onChanged: (value) {
                            code = value; // Capture the code input
                          },
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(result), // Display the result here
                    ),
                  ),
                  // Add more fields as necessary
                ],
              ),
            ),
          ),
          // Chat interface
          if (isChatOpen)
            GestureDetector(
              onTap: () {
                setState(() {
                  isChatOpen = false; // Close chat on background tap
                });
              },
              child: Container(
                color: Colors.black54, // Dark background
                child: Center(
                  child: Container(
                    width: 300, // Set a fixed width for the chat dialog
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chat history
                        Container(
                          constraints: BoxConstraints(
                            maxHeight:
                                300, // Set a maximum height for the chat history
                          ),
                          child: ListView.builder(
                            itemCount: chatHistory.length,
                            itemBuilder: (context, index) {
                              String message = chatHistory[index];

                              if (message.startsWith('You:')) {
                                // User message
                                return _buildUserMessage(
                                    message.replaceFirst('You: ', ''));
                              } else if (message.startsWith('Guide:')) {
                                // Guide message
                                String guideContent =
                                    message.replaceFirst('Guide: ', '');
                                return _buildFormattedText(guideContent);
                              } else {
                                // Other messages
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(message),
                                );
                              }
                            },
                          ),
                        ),
                        // Input and buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  chatInput = value;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Ask a question...',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.send),
                              onPressed: () async {
                                if (chatInput.trim().isNotEmpty) {
                                  setState(() {
                                    chatHistory.add('You: $chatInput');
                                  });
                                  await generateAnswer(chatInput);
                                  setState(() {
                                    chatInput =
                                        ''; // Clear the input field after sending
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.lightbulb),
                              onPressed: () async {
                                await guideCode();
                              },
                            ),
                          ],
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

  Future<void> _runCode() async {
    try {
      final response = await http.post(
        Uri.parse('https://emkc.org/api/v2/piston/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'language': selectedLanguage,
          'version': LANGUAGE_VERSIONS[selectedLanguage],
          'files': [
            {
              'content': code,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          result = data['run']['output']; // Capture the output
        });

        // Check against test cases
        int totalTestCases = widget.problem['testCases'].length;
        int passedTestCases = _checkTestcase(data['run']['output'].split('\n'));

        // Enable submit button if all test cases passed
        isSubmitEnabled = (passedTestCases == totalTestCases);

        // Show Snackbar with results
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You pass $passedTestCases of $totalTestCases test cases.',
            ),
          ),
        );
      } else {
        setState(() {
          result = 'Error: ${response.body}'; // Handle error
        });
      }
    } catch (e) {
      setState(() {
        result = 'Exception: $e'; // Log the exception
      });
    }
  }

  void _showSubmitDialog() async {
    await _requestRating(); // Call the function to request ratings
    await _saveSolvedProblem(); // Call the function to save the solved problem
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Good work!"),
          content: Container(
            constraints: BoxConstraints(maxHeight: 400), // Set a max height
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Congratulations on acing the test! Your hard work and dedication have paid off. 🎉🎉🎉",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text("Your Ratings:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  // Ensure ratings are set before displaying the chart
                  if (correctnessRating > 0 ||
                      performanceRating > 0 ||
                      clarityRating > 0)
                    SizedBox(
                      width: 300, // Set a fixed width
                      height: 200, // Set a fixed height
                      child: BarChart(
                        BarChartData(
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: correctnessRating,
                                  color: Colors.green,
                                  width: 20,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: performanceRating,
                                  color: Colors.blue,
                                  width: 20,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: clarityRating,
                                  color: Colors.orange,
                                  width: 20,
                                ),
                              ],
                            ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: false), // Hide left titles
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0:
                                      return Text(correctnessRating
                                          .toString()); // Show correctness score
                                    case 1:
                                      return Text(performanceRating
                                          .toString()); // Show performance score
                                    case 2:
                                      return Text(clarityRating
                                          .toString()); // Show clarity score
                                    default:
                                      return Text('');
                                  }
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              // Add this line to hide top titles
                              sideTitles: SideTitles(
                                showTitles: false, // Hide top titles
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Text("No ratings available."), // Fallback if no ratings
                  // Add this text note below the chart
                  Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: Colors.green, // Correctness color
                          ),
                          SizedBox(width: 5),
                          Text('Correctness'),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: Colors.blue, // Performance color
                          ),
                          SizedBox(width: 5),
                          Text('Performance'),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: Colors.orange, // Clarity color
                          ),
                          SizedBox(width: 5),
                          Text('Clarity'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestRating() async {
    final sourceCode = code; // Get the code from the editor
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
                      'Rate the following code on a scale from 1 to 100 for the following criteria:\n\nCorrectness\nPerformance\nClarity\nGive me the answer of numbers in order only, for example: 90\n70\n80\n.\n\nCode:\n$sourceCode',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final ratingsText = jsonDecode(response.body)['candidates'][0]
                ['content']['parts'][0]['text']
            .trim();
        final ratings = ratingsText.split('\n');
        if (ratings.length == 3) {
          setState(() {
            correctnessRating = double.parse(ratings[0]);
            performanceRating = double.parse(ratings[1]);
            clarityRating = double.parse(ratings[2]);
          });
        }
      }
    } catch (error) {
      print('Error while requesting ratings: $error');
    }
  }

  int _checkTestcase(List<String> userOutput) {
    int passed = 0;
    final expectedOutputs = widget.problem['testCases']
        .map((testCase) => testCase['outputText'].trim())
        .toList();

    for (var expectedOutput in expectedOutputs) {
      if (userOutput.contains(expectedOutput)) {
        passed++;
      }
    }
    return passed;
  }

  List<Widget> _buildConstraints(dynamic constraints) {
    if (constraints == null || constraints.isEmpty) {
      return [Text('No constraints available')];
    }
    return constraints
        .split('. ')
        .map<Widget>((constraint) => Text('- $constraint'))
        .toList();
  }

  List<Widget> _buildTestCases(List<dynamic> testCases) {
    if (testCases.isEmpty) {
      return [Text('No test cases available')];
    }
    return testCases.asMap().entries.map<Widget>((entry) {
      int index = entry.key;
      var testCase = entry.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Test Case ${index + 1}:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Input: ${testCase['inputText']}'),
          Text('Output: ${testCase['outputText']}'),
          Text('Explanation: ${testCase['explanation']}'),
          SizedBox(height: 10),
        ],
      );
    }).toList();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.yellow;
      case 'hard':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Mode _getLanguageMode(String language) {
    switch (language) {
      case 'java':
        return java;
      case 'javascript':
        return javascript;
      case 'python':
        return python;
      case 'php':
        return php;
      case 'typescript':
        return typescript;
      default:
        return javascript; // Fallback to JavaScript
    }
  }

  Future<void> generateAnswer(String question) async {
    setState(() {
      chatHistory
          .add('Gemini is thinking... \n It might take up to 10 seconds.');
    });

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
                      'Imagine you are an AI coding assistant named CodeHub. This is the coding problem I\'m doing right now:\n' +
                          'Title: ' +
                          widget.problem['title'] +
                          '\n' +
                          'Statement: ' +
                          widget.problem['statement'] +
                          '\n' +
                          'Answer the question: ' +
                          question,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final answer = jsonDecode(response.body)['candidates'][0]['content']
            ['parts'][0]['text'];
        setState(() {
          chatHistory.removeLast(); // Remove the thinking message
          chatHistory.add('Gemini: $answer');
        });
      } else {
        setState(() {
          chatHistory.removeLast(); // Remove the thinking message
          chatHistory
              .add('Gemini: Sorry - Something went wrong. Please try again!');
        });
      }
    } catch (error) {
      print(error);
      setState(() {
        chatHistory.removeLast(); // Remove the thinking message
        chatHistory
            .add('Gemini: Sorry - Something went wrong. Please try again!');
      });
    }
  }

  Future<void> guideCode() async {
    setState(() {
      chatHistory.add('You: Generate Guide');
      chatHistory.add('Generating guide... \n It might take up to 10 seconds.');
    });

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
                  'text': 'Imagine you are a professor majoring in Information Technology. Teach me how to solve this problem:\n' +
                      'Title: ' +
                      widget.problem['title'] +
                      '\n' +
                      'Statement: ' +
                      widget.problem['statement'] +
                      '\n' +
                      "Show me ideas and step-by-step instructions to help me find a way to solve a code problem. Don't write out hint code or example code, let me write it myself.",
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final guide = jsonDecode(response.body)['candidates'][0]['content']
            ['parts'][0]['text'];
        setState(() {
          chatHistory.removeLast(); // Remove the generating guide message
          chatHistory.add('Guide: $guide');
        });
      } else {
        setState(() {
          chatHistory.removeLast(); // Remove the generating guide message
          chatHistory
              .add("Guide: Sorry - Couldn't generate guide at this time.");
        });
      }
    } catch (error) {
      print(error);
      setState(() {
        chatHistory.removeLast(); // Remove the generating guide message
        chatHistory.add("Guide: Sorry - Couldn't generate guide at this time.");
      });
    }
  }

  // Function to build formatted text with code snippets and bold text
  Widget _buildFormattedText(String content) {
    List<Widget> children = [];
    List<String> parts = content.split('```');

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Regular text with bold formatting
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildRichText(parts[i]),
        ));
      } else {
        // Code block
        children.add(_buildCodeSnippet(parts[i]));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // Function to build rich text with bold formatting
  Widget _buildRichText(String text) {
    final boldPatterns = [
      RegExp(r'\*\*(.*?)\*\*'), // Matches **text**
      RegExp(r'##(.*?)##'), // Matches ##text##
    ];
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      int closestMatchStart = text.length;
      Match? closestMatch;
      for (final pattern in boldPatterns) {
        final match = pattern.firstMatch(text.substring(start));
        if (match != null && match.start < closestMatchStart) {
          closestMatchStart = match.start;
          closestMatch = match;
        }
      }

      if (closestMatch != null) {
        if (closestMatch.start > 0) {
          spans.add(TextSpan(
              text: text.substring(start, start + closestMatch.start)));
        }
        spans.add(TextSpan(
          text: closestMatch.group(1),
          style: TextStyle(fontWeight: FontWeight.bold),
        ));
        start += closestMatch.end;
      } else {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
    }

    return RichText(
      text: TextSpan(style: TextStyle(color: Colors.black), children: spans),
    );
  }

  // Function to build the code snippet widget
  Widget _buildCodeSnippet(String codeContent) {
    return Container(
      padding: EdgeInsets.all(8.0),
      margin: EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Code Snippet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: codeContent));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Code copied to clipboard!')),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 4.0),
          Text(
            codeContent,
            style: TextStyle(
                fontFamily: 'Courier', fontSize: 14), // Monospace font
          ),
        ],
      ),
    );
  }

  // Function to build user message widget
  Widget _buildUserMessage(String message) {
    return Container(
      padding: EdgeInsets.all(8.0),
      margin: EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  // Add this method to save the solved problem
  Future<void> _saveSolvedProblem() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'solvedProblems': FieldValue.arrayUnion([widget.problem.id]),
        'recentSolved':
            widget.problem.id, // Store the most recent solved problem
      });
    }
  }
}
