// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_new/screens/user/course_screen.dart';
import 'package:project_new/screens/user/profile_screen.dart';
import 'problems_screen.dart';
import 'solve_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allProblems = [];
  List<DocumentSnapshot> _randomProblems = [];
  int _selectedIndex = 0;

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
    final problems = snapshot.docs;

    setState(() {
      _allProblems = problems;
      _randomProblems = _allProblems..shuffle();
      _randomProblems = _randomProblems.take(5).toList();
    });
  }

  void _onSearchChanged() {
    _searchController.text.toLowerCase();
    setState(() {});
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ProblemsScreen()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => CourseScreen()),
        );
        break;
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ProblemsScreen()),
              );
            },
            child:
                const Text('View All', style: TextStyle(color: Colors.white)),
          ),
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
          Expanded(
            child: ListView.builder(
              itemCount: _randomProblems.length,
              itemBuilder: (context, index) {
                final problem = _randomProblems[index];
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment, color: Colors.black),
            label: 'Problems',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book, color: Colors.black),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
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
