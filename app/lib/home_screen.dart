import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:math';
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
        title: Padding(
          padding: EdgeInsets.only(right: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PopupMenuButton<String>(
                initialValue: appState.currentFeed,
                onSelected: (String newValue) {
                  appState.setCurrentFeed(newValue);
                },
                itemBuilder: (BuildContext context) =>
                    appState.getAvailableFeeds().map((String feed) {
                  return PopupMenuItem<String>(
                    value: feed,
                    child: Text(feed),
                  );
                }).toList(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_drop_down, color: Colors.blue[800]),
                    Text(
                      appState.currentFeed,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: ElevatedButton(
              child: Icon(Icons.add, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
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
                    PostFeed(feedType: appState.currentFeed, sortBy: 'top'),
                    PostFeed(feedType: appState.currentFeed, sortBy: 'recent'),
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
    return StreamBuilder<QuerySnapshot>(
      stream: appState.getPostsStream(feedType),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in PostFeed: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;
        if (sortBy == 'top') {
          posts
              .sort((a, b) => _calculateScore(b).compareTo(_calculateScore(a)));
        }

        return ListView(
          children: posts.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['userId'])
                  .get(),
              builder: (context, userSnapshot) {
                String userName = '@anonymous';
                String profileEmoji = '🫥';
                if (userSnapshot.connectionState == ConnectionState.done) {
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    userName = userData?['userName'] as String? ?? '';
                    profileEmoji = userData?['profileEmoji'] as String? ?? '🫥';
                    if (userName.isEmpty) {
                      userName = '@anonymous';
                    } else {
                      userName = '@$userName';
                    }
                  } else {
                    userName = '@[deleted]';
                  }
                }
                return PostCard(
                  title: data['title'] ?? '',
                  content: data['content'] ?? '',
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

  double _calculateScore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final points = data['points'] as int? ?? 0;
    final commentCount = data['commentCount'] as int? ?? 0;
    final timestamp = data['timestamp'] as Timestamp?;

    if (timestamp == null) return 0;

    final ageInHours = DateTime.now().difference(timestamp.toDate()).inHours;
    final gravity = 1.8;

    return (points + (commentCount * 0.5)) / pow((ageInHours + 2), gravity);
  }
}
