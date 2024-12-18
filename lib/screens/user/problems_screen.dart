// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors, unnecessary_import, unused_element

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_new/screens/user/course_screen.dart';
import 'package:project_new/screens/user/home_screen.dart';
import 'package:project_new/screens/user/profile_screen.dart';
import 'solve_screen.dart';
import 'package:forui/forui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/language_controller.dart';

class ProblemsScreen extends StatefulWidget {
  @override
  _ProblemsScreenState createState() => _ProblemsScreenState();
}

class _ProblemsScreenState extends State<ProblemsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allProblems = [];
  List<DocumentSnapshot> _filteredProblems = [];
  int _selectedIndex = 1;

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
    final languageController = Provider.of<LanguageController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: FutureBuilder<String>(
          future: languageController
              .translateText('Problems'), // Translate the title
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Problems'); // Fallback text while loading
            }
            if (snapshot.hasError) {
              return Text('Problems'); // Fallback text in case of error
            }
            return Text(
              snapshot.data ?? 'Problems', // Use translated title
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
            );
          },
        ),
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
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _filteredProblems.length,
              itemBuilder: (context, index) {
                final problem = _filteredProblems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 20.0),
                  child: ProblemCard(
                    problem: problem,
                    onPress: () {
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
      bottomNavigationBar: FutureBuilder<List<String>>(
        future: Future.wait([
          languageController.translateText('Home'),
          languageController.translateText('Problems'),
          languageController.translateText('Courses'),
          languageController.translateText('Profile'),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.assignment), label: 'Problems'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.book), label: 'Courses'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black.withOpacity(0.3),
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              onTap: _onItemTapped,
            );
          }

          if (snapshot.hasError) {
            return BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.assignment), label: 'Problems'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.book), label: 'Courses'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black.withOpacity(0.3),
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              onTap: _onItemTapped,
            );
          }

          final labels = snapshot.data!;

          return BottomNavigationBar(
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: labels[0]),
              BottomNavigationBarItem(
                  icon: Icon(Icons.assignment), label: labels[1]),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: labels[2]),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: labels[3]),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black.withOpacity(0.3),
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            onTap: _onItemTapped,
          );
        },
      ),
    );
  }
}

class ProblemCard extends StatelessWidget {
  final DocumentSnapshot problem;
  final VoidCallback onPress;

  const ProblemCard({
    super.key,
    required this.problem,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);

    return GestureDetector(
      onTap: onPress, // Trigger the onPress callback
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FutureBuilder<String>(
                      future: languageController.translateText(
                          problem['title']), // Translate the title
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text("Error translating title");
                        }
                        return Text(
                          snapshot.data ??
                              problem['title'], // Use translated title
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FBadge(
                    label: Text(
                      problem['difficulty'], // Use difficulty directly
                      style: TextStyle(
                        color: _getDifficultyColor(problem['difficulty']),
                      ),
                    ),
                    style: FBadgeStyle.outline,
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                problem['type'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4.0),
            ],
          ),
        ),
      ),
    );
  }
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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
          child: ProblemCard(
            problem: problem,
            onPress: () {
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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
          child: ProblemCard(
            problem: problem,
            onPress: () {
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
}
