// File: app/lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'post_card.dart';
import 'post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(appState.currentFeed),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.yellow[700], size: 18),
                SizedBox(width: 2),
                Text(
                  '${appState.userPoints}',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: ElevatedButton(
              child: Icon(Icons.add, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800]?.withOpacity(0.8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(8),
                minimumSize: Size(40, 40),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PostScreen(currentFeed: appState.currentFeed),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Top'),
                  Tab(text: 'Recent'),
                ],
                indicatorColor: Colors.blue[800],
                labelColor: Colors.blue[800],
                unselectedLabelColor: Colors.grey,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    PostFeed(feedType: appState.currentFeed, sortBy: 'points'),
                    PostFeed(
                        feedType: appState.currentFeed, sortBy: 'timestamp'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostFeed extends StatelessWidget {
  final String feedType;
  final String sortBy;

  const PostFeed({Key? key, required this.feedType, required this.sortBy})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentFeed = feedType == 'My Command' ? appState.command : feedType;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('feed', isEqualTo: currentFeed)
          .orderBy(sortBy, descending: true)
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
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['userId'])
                  .get(),
              builder: (context, userSnapshot) {
                String userName = '@[deleted]';
                String profileEmoji = '🫥';
                if (userSnapshot.connectionState == ConnectionState.done &&
                    userSnapshot.hasData) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  userName = userData?['userName'] as String? ?? '';
                  profileEmoji = userData?['profileEmoji'] as String? ?? '🫥';
                  if (userName.isEmpty) {
                    userName = '@[deleted]';
                  } else {
                    userName = '@$userName';
                  }
                }
                return PostCard(
                  title: data['title'] ?? '',
                  content: data['content'] ?? '',
                  points: data['points'] ?? 0,
                  commentCount: data['commentCount'] ?? 0,
                  timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
                  postId: document.id,
                  userId: data['userId'] ?? '',
                  profileEmoji: profileEmoji,
                  userName: userName,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
