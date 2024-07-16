// File: app/lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'post_detail_screen.dart';

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
              Tab(text: 'Main Feed'),
              Tab(text: 'New Posts'),
            ],
            indicatorColor: Colors.blue[800],
            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                PostFeed(sortBy: 'points'),
                PostFeed(sortBy: 'timestamp'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostFeed extends StatelessWidget {
  final String sortBy;

  const PostFeed({Key? key, required this.sortBy}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentFeed = Provider.of<AppState>(context).command ?? 'All DOD';
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

class PostCard extends StatelessWidget {
  final String title;
  final String content;
  final int points;
  final int commentCount;
  final DateTime timestamp;
  final String postId;
  final String userId;

  const PostCard({
    Key? key,
    required this.title,
    required this.content,
    required this.points,
    required this.commentCount,
    required this.timestamp,
    required this.postId,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isCreator = appState.userId == userId;
    final isSaved = appState.savedPosts.contains(postId);

    return Card(
      margin: EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: postId),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCreator)
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmation(context),
                    ),
                ],
              ),
              SizedBox(height: 8.0),
              Text(content),
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_upward),
                        onPressed: () {
                          appState.updatePostPoints(postId, 1);
                        },
                      ),
                      Text('$points'),
                      IconButton(
                        icon: Icon(Icons.arrow_downward),
                        onPressed: () {
                          appState.updatePostPoints(postId, -1);
                        },
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.comment),
                      SizedBox(width: 4),
                      Text('$commentCount'),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? Colors.blue[800] : null,
                        ),
                        onPressed: () {
                          appState.toggleSavedPost(postId);
                        },
                      ),
                      Text(getRelativeTime(timestamp)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text(
              'Are you sure you want to delete this post? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<AppState>(context, listen: false)
                    .deletePost(postId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

String getRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'Now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  } else {
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }
}
