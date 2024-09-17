// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProblemScreen extends StatefulWidget {
  final VoidCallback onProblemAdded;

  const AddProblemScreen({super.key, required this.onProblemAdded});

  @override
  _AddProblemScreenState createState() => _AddProblemScreenState();
}

class _AddProblemScreenState extends State<AddProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String statement = '';
  String difficulty = '';
  String type = '';
  String constraints = '';
  List<Map<String, String>> testCases = [];

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
      // Check if a problem with the same title already exists
      final existingProblem = await FirebaseFirestore.instance
          .collection('problems')
          .where('title', isEqualTo: title)
          .get();

      if (existingProblem.docs.isEmpty) {
        // Add new problem if no existing problem with the same title
        await FirebaseFirestore.instance.collection('problems').add({
          'title': title,
          'statement': statement,
          'difficulty': difficulty,
          'type': type,
          'constraints': constraints,
          'testCases': testCases,
        });
        widget.onProblemAdded(); // Call the callback function
        Navigator.of(context).pop();
      } else {
        // Show a message if a problem with the same title already exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A problem with the same title already exists.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Problem')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
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
                  child: const Text('Add Problem'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
