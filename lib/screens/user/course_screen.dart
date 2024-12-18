// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors, deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'home_screen.dart';
import 'lecture_screen.dart';
import 'problems_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import '../../controllers/language_controller.dart';

class CourseScreen extends StatefulWidget {
  @override
  _CourseScreenState createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  int _selectedIndex = 2;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _courses = [];
  List<DocumentSnapshot> _filteredCourses = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    final snapshot = await _firestore.collection('courses').get();
    setState(() {
      _courses = snapshot.docs;
      _filteredCourses = _courses;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _filteredCourses = _courses
          .where((course) => course['title']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
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
        if (_filteredCourses.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LectureScreen(
                  courseId: _filteredCourses[index].id), // Pass the course ID
            ),
          );
        }
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
              .translateText('Courses'), // Translate the title
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Courses'); // Fallback text while loading
            }
            if (snapshot.hasError) {
              return Text('Courses'); // Fallback text in case of error
            }
            return Text(
              snapshot.data ?? 'Courses', // Use translated title
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filteredCourses.length,
              itemBuilder: (context, index) {
                final course = _filteredCourses[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 8.0),
                  child: FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: FutureBuilder<String>(
                                  future: languageController.translateText(course[
                                      'title']), // Translate the course title
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text(course['title'],
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight
                                                  .bold)); // Fallback text while loading
                                    }
                                    if (snapshot.hasError) {
                                      return Text(course['title'],
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight
                                                  .bold)); // Fallback text in case of error
                                    }
                                    return Text(
                                      snapshot.data ??
                                          course[
                                              'title'], // Use translated title
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    );
                                  },
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey, width: 1),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  course['language_short'],
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text(
                            course['author'],
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => LectureScreen(
                                        courseId:
                                            course.id), // Pass the course ID
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: CachedNetworkImage(
                                  imageUrl: course['image_cover'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
