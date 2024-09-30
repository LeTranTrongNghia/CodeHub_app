// ignore_for_file: use_super_parameters, prefer_const_constructors, unused_import, must_be_immutable, depend_on_referenced_packages, implementation_imports, constant_identifier_names, prefer_const_constructors_in_immutables, library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart'; // Add this import
import 'package:highlight/src/mode.dart';
import 'package:http/http.dart' as http; // Add this import
import 'dart:convert'; // Add this import
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this import for charting
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this import

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
  String selectedLanguage = 'python'; // Default language
  String code = ''; // Code input by the user
  String result = ''; // Result from the API
  late CodeController controller;
  bool isSubmitEnabled = false; // Track if submit button should be enabled
  double correctnessRating = 0;
  double performanceRating = 0;
  double clarityRating = 0;

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
      appBar: AppBar(
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
      body: Padding(
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
                'Statement: ${widget.problem['statement'] ?? 'No statement available'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Constraints:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ..._buildConstraints(widget.problem['constraints']),
              SizedBox(height: 10),
              Text(
                'Test Cases:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ..._buildTestCases(widget.problem['testCases']),
              // Code Editor Section
              SizedBox(height: 20),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Aligns items
                children: [
                  DropdownButton<String>(
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
                    child: Text('Run'),
                  ),
                ],
              ),
              CodeTheme(
                data: CodeThemeData(
                    styles: monokaiSublimeTheme), // Apply the theme
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: controller, // Use the controller
                    onChanged: (value) {
                      code = value; // Capture the code input
                    },
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
          Text('Explanation: ${testCase['explanation']}'),
          Text('Input: ${testCase['inputText']}'),
          Text('Output: ${testCase['outputText']}'),
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
}
