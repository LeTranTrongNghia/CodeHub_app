// ignore_for_file: use_super_parameters, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SolveScreen extends StatelessWidget {
  final DocumentSnapshot problem;

  const SolveScreen({Key? key, required this.problem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(problem['title']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title: ${problem['title']}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Type: ${problem['type']}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                'Difficulty: ${problem['difficulty']}',
                style: TextStyle(
                  fontSize: 18,
                  color: _getDifficultyColor(problem['difficulty']),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Statement: ${problem['statement'] ?? 'No statement available'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Constraints:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ..._buildConstraints(problem['constraints']),
              SizedBox(height: 10),
              Text(
                'Test Cases:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ..._buildTestCases(problem['testCases']),
              // Add more fields as necessary
            ],
          ),
        ),
      ),
    );
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
}
