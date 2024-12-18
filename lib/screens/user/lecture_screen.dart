// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables, library_private_types_in_public_api, prefer_const_constructors, avoid_print, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'quiz_screen.dart';

class LectureScreen extends StatefulWidget {
  final String courseId;

  LectureScreen({required this.courseId});

  @override
  _LectureScreenState createState() => _LectureScreenState();
}

class _LectureScreenState extends State<LectureScreen> {
  late String videoLink;
  List<Map<String, String>> lectures = [];
  late YoutubePlayerController _controller; // Change to YoutubePlayerController

  @override
  void initState() {
    super.initState();
    _fetchCourseData(); // Fetch course data
  }

  // Fetch course data from Firestore
  Future<void> _fetchCourseData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .get();
    final data = snapshot.data();

    if (data != null) {
      setState(() {
        videoLink = data['video_link'];
        // Safely convert lectures to List<Map<String, String>>
        lectures = List<Map<String, String>>.from(
          (data['lectures'] as List<dynamic>).map((item) {
            return Map<String, String>.from(item as Map<dynamic, dynamic>);
          }),
        );

        // Initialize the YoutubePlayerController
        String? videoId =
            YoutubePlayer.convertUrlToId(videoLink); // Extract video ID
        if (videoId != null) {
          _controller = YoutubePlayerController(
            initialVideoId: videoId, // Use the extracted video ID
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
            ),
          );
        } else {
          // Handle the case where the video ID is null
          // You can show an error message or a placeholder
          print("Invalid YouTube URL: $videoLink");
        }
      });
    }
  }

  // Hàm phát video tại thời gian cụ thể
  void _playVideoAt(String startTime) {
    final duration = _parseDuration(startTime);
    _controller.seekTo(duration);
  }

  // Hàm chuyển đổi thời gian thành Duration
  Duration _parseDuration(String time) {
    final parts = time.split(':').map(int.parse).toList();
    if (parts.length == 1) {
      return Duration(seconds: parts[0]);
    } else if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    } else if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    } else {
      return Duration.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Lectures'),
        actions: [
          // Add this section for the quiz button
          IconButton(
            icon: Icon(Icons.quiz),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                      courseId: widget.courseId), // Navigate to QuizScreen
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Check if the platform is web
          Expanded(
            child: kIsWeb
                ? Center(
                    child: Text('This feature is not supported on the web.'))
                : YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                    onReady: () {
                      // You can add any additional functionality here
                    },
                  ),
          ),
          // List of lectures
          Expanded(
            child: ListView.builder(
              itemCount: lectures.length,
              itemBuilder: (context, index) {
                final lecture = lectures[index];
                return Card(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.grey,
                    ),
                  ),
                  child: ListTile(
                    title: Text(lecture['title_lecture']!),
                    subtitle: Text(lecture['time']!),
                    onTap: () => _playVideoAt(lecture['time']!),
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

// Video player screen to play the video
class VideoPlayerScreen extends StatelessWidget {
  final String videoUrl;

  VideoPlayerScreen({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl)!; // Extract video ID
    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: true,
      ),
    );
  }
}
