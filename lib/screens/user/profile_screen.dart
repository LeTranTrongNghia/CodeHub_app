// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors, unused_local_variable, unused_element, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_screen.dart';
import 'home_screen.dart';
import 'lecture_screen.dart';
import 'problems_screen.dart';
import 'course_screen.dart';
import 'solve_screen.dart';
import 'package:provider/provider.dart';
import '../../controllers/language_controller.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 3;

  String photoURLValue = ''; // Define the photoURLValue variable

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

  Future<Map<String, dynamic>?> _getUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null) {
        final String recentSolvedId = userData['recentSolved'] ?? '';
        if (recentSolvedId.isNotEmpty) {
          final DocumentSnapshot recentProblem =
              await _firestore.collection('problems').doc(recentSolvedId).get();
          userData['recentProblem'] = recentProblem.data();
        }

        // Remove recentLectureName logic
      }
      return userData;
    }
    return null;
  }

  Future<List<DocumentSnapshot>> _getSolvedProblems(
      List<String> solvedProblemIds) async {
    final List<DocumentSnapshot> solvedProblems = [];
    for (String id in solvedProblemIds) {
      final DocumentSnapshot problemDoc =
          await _firestore.collection('problems').doc(id).get();
      if (problemDoc.exists) {
        solvedProblems.add(problemDoc);
      }
    }
    return solvedProblems;
  }

  // Add this new method to handle the username update
  void _showEditUsernameDialog(
      BuildContext context, Map<String, dynamic> userData) {
    final _usernameController =
        TextEditingController(text: userData['username']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Edit Username'),
          content: TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'New Username'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final User? user = _auth.currentUser;
                if (user != null) {
                  await _firestore.collection('users').doc(user.uid).update({
                    'username': _usernameController.text,
                    'updated_at': FieldValue.serverTimestamp(),
                  });
                  Navigator.of(context).pop();
                  setState(
                      () {}); // Refresh the state to reflect the new username
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);
    final size = MediaQuery.of(context).size; // Get the screen size

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: FutureBuilder<String>(
          future: languageController.translateText('Profile Screen'),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ?? 'Profile Screen', // Fallback to original title
              style: TextStyle(color: Colors.black),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              _auth.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred.'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No user data found.'));
          }

          final userData = snapshot.data!;
          final String displayName = userData['username'] ?? 'User';
          final String email = userData['email'] ?? 'No email';
          final String role = userData['role'] ?? 'N/A'; // Fetching role
          final List<dynamic> solvedProblems = userData['solvedProblems'] ?? [];
          final List<dynamic> attendedCourses =
              userData['attendedCourses'] ?? [];
          final String avatarUrl = userData['avatar'] ?? '';

          // Fetch solved problems based on the IDs
          return FutureBuilder<List<DocumentSnapshot>>(
            future: _getSolvedProblems(List<String>.from(solvedProblems)),
            builder: (context, solvedSnapshot) {
              if (solvedSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (solvedSnapshot.hasError) {
                return const Center(
                    child: Text(
                        'An error occurred while fetching solved problems.'));
              }
              if (!solvedSnapshot.hasData || solvedSnapshot.data!.isEmpty) {
                return const Center(child: Text('No solved problems found.'));
              }

              final List<DocumentSnapshot> _SolvedProblems =
                  solvedSnapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: 53.w, right: 56.w, top: 35.h, bottom: 30.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onDoubleTap: () {
                              _showEditUsernameDialog(context, userData);
                            },
                            child: FutureBuilder<String>(
                              future:
                                  languageController.translateText(displayName),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ??
                                      displayName, // Fallback to original displayName
                                  style: GoogleFonts.workSans(
                                    textStyle: TextStyle(
                                      fontSize: 20.sp,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            width: 96.r,
                            height: 96.r,
                            margin: EdgeInsets.only(top: 35.h, bottom: 19.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(96.r),
                              color: Colors.grey,
                              image: avatarUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                          FutureBuilder<String>(
                            future: languageController.translateText(email),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ??
                                    email, // Fallback to original email
                                style: GoogleFonts.workSans(
                                  textStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 24.h),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // Center the row
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FutureBuilder<String>(
                                      future: languageController
                                          .translateText(role),
                                      builder: (context, snapshot) {
                                        return Text(
                                          snapshot.data ??
                                              role, // Fallback to original role
                                          style: GoogleFonts.workSans(
                                            textStyle: TextStyle(
                                              fontSize: 20.sp,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    FutureBuilder<String>(
                                      future: languageController
                                          .translateText("Role"),
                                      builder: (context, snapshot) {
                                        return Text(
                                          snapshot.data ??
                                              "Role", // Fallback to original "Role"
                                          style: GoogleFonts.workSans(
                                            textStyle: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 20), // Add space between columns
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FutureBuilder<String>(
                                      future: languageController.translateText(
                                          '${attendedCourses.length}'),
                                      builder: (context, snapshot) {
                                        return Text(
                                          snapshot.data ??
                                              '${attendedCourses.length}', // Fallback to original count
                                          style: GoogleFonts.workSans(
                                            textStyle: TextStyle(
                                              fontSize: 20.sp,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    FutureBuilder<String>(
                                      future: languageController
                                          .translateText("Courses Attended"),
                                      builder: (context, snapshot) {
                                        return Text(
                                          snapshot.data ??
                                              "Courses Attended", // Fallback to original "Courses Attended"
                                          style: GoogleFonts.workSans(
                                            textStyle: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 20), // Add space between columns
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FutureBuilder<String>(
                                      future: languageController.translateText(
                                          '${solvedProblems.length}'),
                                      builder: (context, snapshot) {
                                        return Text(
                                          snapshot.data ??
                                              '${solvedProblems.length}', // Fallback to original count
                                          style: GoogleFonts.workSans(
                                            textStyle: TextStyle(
                                              fontSize: 20.sp,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    FutureBuilder<String>(
                                      future: languageController
                                          .translateText("Problems Solved"),
                                      builder: (context, snapshot) {
                                        return Text(
                                          snapshot.data ??
                                              "Problems Solved", // Fallback to original "Problems Solved"
                                          style: GoogleFonts.workSans(
                                            textStyle: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: FutureBuilder<String>(
                        future: languageController.translateText(
                            'Attended Courses'), // Translate "Attended Courses"
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ??
                                'Attended Courses', // Fallback text
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: GoogleFonts.workSans().fontFamily,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: SizedBox(
                        width: size.width,
                        height: 240,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FutureBuilder<Map<String, dynamic>?>(
                                future:
                                    _getUserData(), // Fetch user data to get attendedCourses
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (userSnapshot.hasError ||
                                      !userSnapshot.hasData) {
                                    return Text("Something went wrong");
                                  }

                                  final userData = userSnapshot.data!;
                                  final List<dynamic> attendedCourses =
                                      userData['attendedCourses'] ?? [];

                                  return FutureBuilder<QuerySnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('courses')
                                        .get(),
                                    builder: (context, courseSnapshot) {
                                      if (courseSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }
                                      if (courseSnapshot.hasError) {
                                        return Text("Something went wrong");
                                      }

                                      final courses = courseSnapshot.data!.docs
                                          .where((course) {
                                        return attendedCourses.contains(course
                                            .id); // Filter courses by attendedCourses
                                      }).toList();

                                      return ListView.separated(
                                        itemCount: courses.length,
                                        shrinkWrap: true,
                                        scrollDirection: Axis.horizontal,
                                        physics: NeverScrollableScrollPhysics(),
                                        separatorBuilder: (context, index) {
                                          return SizedBox(width: 20.h);
                                        },
                                        itemBuilder: (context, index) {
                                          var course = courses[index].data()
                                              as Map<String, dynamic>;
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      LectureScreen(
                                                          courseId: courses[
                                                                  index]
                                                              .id), // Pass the course ID
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: 244.h,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 244.w,
                                                    height: 160.h,
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                            course[
                                                                'image_cover']),
                                                        fit: BoxFit.cover,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8.h),
                                                  FutureBuilder<String>(
                                                    future: languageController
                                                        .translateText(course[
                                                            'title']), // Translate course title
                                                    builder:
                                                        (context, snapshot) {
                                                      return Text(
                                                        snapshot.data ??
                                                            course[
                                                                'title'], // Fallback to original title
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    course[
                                                        'author'], // Displaying author
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.only(left: 20.h, top: 30.h, bottom: 10.h),
                      child: FutureBuilder<String>(
                        future: languageController.translateText(
                            'Solved Problems'), // Translate "Solved Problems"
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Solved Problems', // Fallback text
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: GoogleFonts.workSans().fontFamily,
                            ),
                          );
                        },
                      ),
                    ),
                    Problems(
                        problems:
                            _SolvedProblems), // Pass the list of solved problems
                  ],
                ),
              );
            },
          );
        },
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

class Problems extends StatelessWidget {
  final List<DocumentSnapshot> problems;

  const Problems({super.key, required this.problems});

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);

    return Column(
      children: [
        const SizedBox(height: 10.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: problems.length,
          itemBuilder: (context, index) {
            final problem = problems[index];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
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
      ],
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
                          problem['title']), // Translate problem title
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ??
                              problem['title'], // Fallback to original title
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
                      problem['difficulty'],
                      style: TextStyle(
                          color: _getDifficultyColor(problem['difficulty'])),
                    ),
                    style: FBadgeStyle.outline,
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              FutureBuilder<String>(
                future: languageController
                    .translateText(problem['type']), // Translate problem type
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ??
                        problem['type'], // Fallback to original type
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  );
                },
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
