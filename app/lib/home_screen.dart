// File: app/lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'post_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'All Posts'),
              Tab(text: 'My Command'),
            ],
            indicatorColor: Colors.blue[800],
            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                PostFeed(feedType: 'All DOD'),
                PostFeed(feedType: 'My Command'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostFeed extends StatelessWidget {
  final String feedType;

  const PostFeed({Key? key, required this.feedType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentFeed = feedType == 'My Command' ? appState.command : 'All DOD';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('feed', isEqualTo: currentFeed)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in PostFeed: ${snapshot.error}');
          print('Error details:');
          print(snapshot.error.toString());
          if (snapshot.error is FirebaseException) {
            FirebaseException e = snapshot.error as FirebaseException;
            print('Firebase Exception Code: ${e.code}');
            print('Firebase Exception Message: ${e.message}');
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return PostCard(
              title: data['title'] ?? '',
              content: data['content'] ?? '',
              points: data['points'] ?? 0,
              commentCount: data['commentCount'] ?? 0,
              timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
              postId: document.id,
              userId: data['userId'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }
}
