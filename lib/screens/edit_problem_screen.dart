// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProblemScreen extends StatefulWidget {
  final DocumentSnapshot problem;
  final VoidCallback onProblemEdited;

  const EditProblemScreen(
      {super.key, required this.problem, required this.onProblemEdited});

  @override
  _EditProblemScreenState createState() => _EditProblemScreenState();
}

class _EditProblemScreenState extends State<EditProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  late String title;
  late String statement;
  late String difficulty;
  late String type;
  late String constraints;
  late List<Map<String, String>> testCases;

  @override
  void initState() {
    super.initState();
    title = widget.problem['title'];
    statement = widget.problem['statement'];
    difficulty = widget.problem['difficulty'];
    type = widget.problem['type'];
    constraints = widget.problem['constraints'];
    testCases = (widget.problem['testCases'] as List)
        .map((testCase) => Map<String, String>.from(testCase))
        .toList();
  }

  void _addTestCase() {
    setState(() {
      testCases.add({'inputText': '', 'outputText': '', 'explanation': ''});
    });
  }

  void _removeTestCase(int index) {
    setState(() {
      testCases.removeAt(index);
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('problems')
          .doc(widget.problem.id)
          .update({
        'title': title,
        'statement': statement,
        'difficulty': difficulty,
        'type': type,
        'constraints': constraints,
        'testCases': testCases,
      });
      widget.onProblemEdited(); // Call the callback function
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Problem')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (value) {
                    setState(() {
                      title = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: statement,
                  decoration: const InputDecoration(labelText: 'Statement'),
                  onChanged: (value) {
                    setState(() {
                      statement = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a statement';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  onChanged: (value) {
                    setState(() {
                      difficulty = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a difficulty';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  onChanged: (value) {
                    setState(() {
                      type = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a type';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: constraints,
                  decoration: const InputDecoration(labelText: 'Constraints'),
                  onChanged: (value) {
                    setState(() {
                      constraints = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter constraints';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text('Test Cases', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: testCases.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        TextFormField(
                          initialValue: testCases[index]['inputText'],
                          decoration:
                              const InputDecoration(labelText: 'Input Text'),
                          onChanged: (value) {
                            setState(() {
                              testCases[index]['inputText'] = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter input text';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          initialValue: testCases[index]['outputText'],
                          decoration:
                              const InputDecoration(labelText: 'Output Text'),
                          onChanged: (value) {
                            setState(() {
                              testCases[index]['outputText'] = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter output text';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          initialValue: testCases[index]['explanation'],
                          decoration:
                              const InputDecoration(labelText: 'Explanation'),
                          onChanged: (value) {
                            setState(() {
                              testCases[index]['explanation'] = value;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeTestCase(index),
                        ),
                        const Divider(),
                      ],
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: _addTestCase,
                  child: const Text('Add Test Case'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Update Problem'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
