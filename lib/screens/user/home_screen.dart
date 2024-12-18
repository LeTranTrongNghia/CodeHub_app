// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors, unused_import, prefer_const_literals_to_create_immutables, unnecessary_import, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'problems_screen.dart';
import 'solve_screen.dart';
import 'course_screen.dart';
import 'profile_screen.dart';
import 'package:forui/forui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'lecture_screen.dart';
import 'package:provider/provider.dart';
import '../../controllers/language_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _allProblems = [];
  List<DocumentSnapshot> _randomProblems = [];
  int _selectedIndex = 0;
  int _solvedProblemsCount = 0;
  int _attendedCoursesCount = 0;

  String homeLabel = 'Home';
  String problemsLabel = 'Problems';
  String coursesLabel = 'Courses';
  String profileLabel = 'Profile';
  String problemsMeasure = 'Problems';
  String coursesMeasure = 'Courses';
  String roleMeasure = 'Role';

  @override
  void initState() {
    super.initState();
    _fetchProblems();
    _fetchTranslations();
  }

  Future<String> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'N/A'; // Return 'N/A' if no user is logged in

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    return userData?['role'] ?? 'N/A'; // Fetching role from user data
  }

  Future<String> getTranslatedUserRole() async {
    final role = await getUserRole(); // Fetch the role
    final languageController =
        Provider.of<LanguageController>(context, listen: false);
    return await languageController.translateText(role); // Translate the role
  }

  void _fetchProblems() async {
    final snapshot = await _firestore.collection('problems').get();
    final problems = snapshot.docs;

    // Fetch user data
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await _firestore.collection('users').doc(user!.uid).get();
    final userData = userDoc.data();

    setState(() {
      _allProblems = problems;
      _randomProblems = _allProblems..shuffle();
      _randomProblems = _randomProblems.take(3).toList();

      // Update JoggingItem values
      _solvedProblemsCount = userData?['solvedProblems']?.length ?? 0;
      _attendedCoursesCount = userData?['attendedCourses']?.length ?? 0;
    });
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

  Future<void> _fetchTranslations() async {
    final languageController =
        Provider.of<LanguageController>(context, listen: false);
    homeLabel = await languageController.translateText('Home');
    problemsLabel = await languageController.translateText('Problems');
    coursesLabel = await languageController.translateText('Courses');
    profileLabel = await languageController.translateText('Profile');
    problemsMeasure = await languageController.translateText('Problems');
    coursesMeasure = await languageController.translateText('Courses');
    roleMeasure = await languageController.translateText('Role');
    setState(() {}); // Update the UI after fetching translations
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);

    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: languageController.translateText('Welcome'),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? 'Welcome',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontFamily: GoogleFonts.workSans().fontFamily,
                              ),
                            );
                          },
                        ),
                        Row(
                          children: [
                            FutureBuilder<String>(
                              future: languageController.translateText('User!'),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? 'User!',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w600,
                                    fontFamily:
                                        GoogleFonts.workSans().fontFamily,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen()),
                        );
                      },
                      child: FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Text("Something went wrong");
                          }

                          if (snapshot.hasData && !snapshot.data!.exists) {
                            return Text("Document does not exist");
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            Map<String, dynamic> data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            return CircleAvatar(
                              radius: 20.w,
                              backgroundColor: Colors.grey,
                              backgroundImage: NetworkImage(data['avatar']),
                            );
                          }

                          return CircularProgressIndicator();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: FutureBuilder<String>(
                  future: languageController.translateText('Stats'),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Stats',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: GoogleFonts.workSans().fontFamily,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                width: size.width,
                padding: EdgeInsets.symmetric(vertical: 20.sp),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Color(0xFF262626),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: getTranslatedUserRole(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator(); // Show loading indicator
                        }
                        if (snapshot.hasError) {
                          return Text("Error fetching role");
                        }

                        return StatsItem(
                          icon: Icons.person, // Updated icon for role
                          value: snapshot.data ?? 'N/A', // Use translated role
                          measure:
                              roleMeasure, // Use translated measure for role
                        );
                      },
                    ),
                    StatsItem(
                      icon: Icons.assignment,
                      value: '$_solvedProblemsCount',
                      measure: problemsMeasure,
                    ),
                    StatsItem(
                      icon: Icons.book,
                      value: '$_attendedCoursesCount',
                      measure: coursesMeasure,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 35.h),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: FutureBuilder<String>(
                  future: languageController.translateText('Featured Courses'),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Featured Courses',
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
              SizedBox(
                width: size.width,
                height: 240,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(width: 20),
                      FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('courses')
                            .get(),
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text("Something went wrong");
                          }

                          final courses = snapshot.data!.docs;

                          return ListView.separated(
                            itemCount: courses.length,
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            physics: NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, index) {
                              return SizedBox(width: 20.h);
                            },
                            itemBuilder: (context, index) {
                              var course =
                                  courses[index].data() as Map<String, dynamic>;

                              // Fetch the translated title
                              Future<String> translatedTitle =
                                  languageController
                                      .translateText(course['title']);

                              return FutureBuilder<String>(
                                future: translatedTitle,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (snapshot.hasError) {
                                    return Text("Error translating title");
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => LectureScreen(
                                              courseId: courses[index]
                                                  .id), // Pass the course ID
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 244.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
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
                                                    course['image_cover']),
                                                fit: BoxFit.cover,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            snapshot.data ??
                                                course[
                                                    'title'], // Use translated title
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
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
                      SizedBox(width: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 35.h),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: FutureBuilder<String>(
                  future: languageController.translateText('Popular problems'),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Popular problems',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: GoogleFonts.workSans().fontFamily,
                      ),
                    );
                  },
                ),
              ),
              PopularProblems(problems: _randomProblems),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home,
                color: _selectedIndex == 0
                    ? Colors.black
                    : Colors.black.withOpacity(0.3)),
            label: homeLabel, // Use pre-fetched translation
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment,
                color: _selectedIndex == 1
                    ? Colors.black
                    : Colors.black.withOpacity(0.3)),
            label: problemsLabel, // Use pre-fetched translation
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book,
                color: _selectedIndex == 2
                    ? Colors.black
                    : Colors.black.withOpacity(0.3)),
            label: coursesLabel, // Use pre-fetched translation
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: _selectedIndex == 3
                    ? Colors.black
                    : Colors.black.withOpacity(0.3)),
            label: profileLabel, // Use pre-fetched translation
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black.withOpacity(0.3),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
        onTap: _onItemTapped,
      ),
    );
  }
}

class StatsItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String measure;

  const StatsItem({
    super.key,
    required this.icon,
    required this.value,
    required this.measure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          icon,
          color: Colors.white,
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: GoogleFonts.workSans().fontFamily,
          ),
        ),
        Text(
          measure,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white,
            fontFamily: GoogleFonts.workSans().fontFamily,
          ),
        ),
      ],
    );
  }
}

class PopularProblems extends StatelessWidget {
  final List<DocumentSnapshot> problems;

  const PopularProblems({super.key, required this.problems});

  @override
  Widget build(BuildContext context) {
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
