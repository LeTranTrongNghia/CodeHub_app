// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'solve_screen.dart';

class ProblemsScreen extends StatefulWidget {
  @override
  _ProblemsScreenState createState() => _ProblemsScreenState();
}

class _ProblemsScreenState extends State<ProblemsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allProblems = [];
  List<DocumentSnapshot> _filteredProblems = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchProblems();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _fetchProblems() async {
    final snapshot = await _firestore.collection('problems').get();
    setState(() {
      _allProblems = snapshot.docs;
      _filteredProblems = _allProblems;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProblems = _allProblems.where((problem) {
        final title = problem['title'].toString().toLowerCase();
        final type = problem['type'].toString().toLowerCase();
        final difficulty = problem['difficulty'].toString().toLowerCase();
        return title.contains(query) ||
            type.contains(query) ||
            difficulty.contains(query);
      }).toList();
    });
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

  BoxShadow _getDifficultyGlow(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 10);
      case 'medium':
        return BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 10);
      case 'hard':
        return BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10);
      default:
        return BoxShadow(color: Colors.transparent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Problems'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProblemSearchDelegate(_allProblems),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchProblems,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredProblems.length,
              itemBuilder: (context, index) {
                final problem = _filteredProblems[index];
                final difficulty = problem['difficulty'];
                return Card(
                  child: ListTile(
                    title: Text(problem['title']),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            problem['type'],
                            softWrap: true,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(difficulty),
                            boxShadow: [_getDifficultyGlow(difficulty)],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              difficulty,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SolveScreen(problem: problem),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProblemSearchDelegate extends SearchDelegate {
  final List<DocumentSnapshot> problems;

  ProblemSearchDelegate(this.problems);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = problems.where((problem) {
      final title = problem['title'].toString().toLowerCase();
      final type = problem['type'].toString().toLowerCase();
      final difficulty = problem['difficulty'].toString().toLowerCase();
      return title.contains(query.toLowerCase()) ||
          type.contains(query.toLowerCase()) ||
          difficulty.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final problem = results[index];
        final difficulty = problem['difficulty'];
        return Card(
          child: ListTile(
            title: Text(problem['title']),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    problem['type'],
                    softWrap: true,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(difficulty),
                    boxShadow: [_getDifficultyGlow(difficulty)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      difficulty,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SolveScreen(problem: problem),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = problems.where((problem) {
      final title = problem['title'].toString().toLowerCase();
      final type = problem['type'].toString().toLowerCase();
      final difficulty = problem['difficulty'].toString().toLowerCase();
      return title.contains(query.toLowerCase()) ||
          type.contains(query.toLowerCase()) ||
          difficulty.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final problem = suggestions[index];
        final difficulty = problem['difficulty'];
        return Card(
          child: ListTile(
            title: Text(problem['title']),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    problem['type'],
                    softWrap: true,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(difficulty),
                    boxShadow: [_getDifficultyGlow(difficulty)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      difficulty,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SolveScreen(problem: problem),
                ),
              );
            },
          ),
        );
      },
    );
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

  BoxShadow _getDifficultyGlow(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 10);
      case 'medium':
        return BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 10);
      case 'hard':
        return BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10);
      default:
        return BoxShadow(color: Colors.transparent);
    }
  }
}
