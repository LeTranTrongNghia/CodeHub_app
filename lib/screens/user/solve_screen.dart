// ignore_for_file: use_super_parameters, prefer_const_constructors, unused_import, must_be_immutable, depend_on_referenced_packages, implementation_imports

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
              ElevatedButton(
                onPressed: () async {
                  await _runCode(); // Call the function to run the code
                },
                child: Text('Run'),
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
