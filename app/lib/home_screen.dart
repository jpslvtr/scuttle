import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showNewPosts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scuttlebutt'),
        actions: [
          Switch(
            value: _showNewPosts,
            onChanged: (value) {
              setState(() {
                _showNewPosts = value;
              });
            },
          ),
          Text(_showNewPosts ? 'New Posts' : 'Main Feed'),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy(_showNewPosts ? 'timestamp' : 'upvotes', descending: true)
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
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return PostCard(
                content: data['content'],
                upvotes: data['upvotes'],
                downvotes: data['downvotes'],
                timestamp: data['timestamp'].toDate(),
              );
            }).toList(),
          );
        },
      ),
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
