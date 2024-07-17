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
        title: Text('Scuttlebutt'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              '${appState.userPoints}',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
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
                    PostFeed(feedType: appState.currentFeed),
                    PostFeed(feedType: 'My Command'),
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

  const PostFeed({Key? key, required this.feedType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentFeed =
        feedType == 'My Command' ? appState.command : appState.currentFeed;

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
              userName: data['userName'] ?? '',
              profileEmoji: data['profileEmoji'] ?? '🙂',
            );
          }).toList(),
        );
      },
    );
  }
}
