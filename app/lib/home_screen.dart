import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: Text('Scuttlebutt')),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Main Feed'),
              Tab(text: 'New Posts'),
            ],
            indicatorColor: Colors.blue[800],
            labelColor:
                Colors.blue[800],
            unselectedLabelColor:
                Colors.grey,
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              PostFeed(sortBy: 'upvotes'),
              PostFeed(sortBy: 'timestamp'),
            ],
          ),
        ),
      ),
    );
  }
}

class PostFeed extends StatelessWidget {
  final String sortBy;

  const PostFeed({Key? key, required this.sortBy}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy(sortBy, descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return PostCard(
              content: data['content'] ?? '',
              upvotes: data['upvotes'] ?? 0,
              downvotes: data['downvotes'] ?? 0,
              timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
            );
          }).toList(),
        );
      },
    );
  }
}

class PostCard extends StatelessWidget {
  final String content;
  final int upvotes;
  final int downvotes;
  final DateTime timestamp;

  const PostCard({
    Key? key,
    required this.content,
    required this.upvotes,
    required this.downvotes,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${upvotes - downvotes} points'),
                Text('${timestamp.toString().split('.')[0]}'),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_upward),
                  onPressed: () {
                    // Implement upvote functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_downward),
                  onPressed: () {
                    // Implement downvote functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.comment),
                  onPressed: () {
                    // Implement comment functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
