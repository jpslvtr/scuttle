// File: app/lib/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic> postData =
                      snapshot.data!.data() as Map<String, dynamic>;

                  return ListView(
                    padding: EdgeInsets.all(16.0),
                    children: [
                      Text(
                        postData['title'] ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(postData['content'] ?? ''),
                      SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('${postData['points']}'),
                              IconButton(
                                icon: Icon(Icons.arrow_upward),
                                onPressed: () {
                                  Provider.of<AppState>(context, listen: false)
                                      .updatePostPoints(postId, 1);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_downward),
                                onPressed: () {
                                  Provider.of<AppState>(context, listen: false)
                                      .updatePostPoints(postId, -1);
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.comment),
                              SizedBox(width: 4),
                              Text('${postData['commentCount']}'),
                            ],
                          ),
                          Text(getRelativeTime(postData['timestamp'].toDate())),
                        ],
                      ),
                      Divider(),
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      CommentList(postId: postId),
                    ],
                  );
                },
              ),
            ),
            CommentInput(postId: postId),
          ],
        ),
      ),
    );
  }
}

class CommentList extends StatelessWidget {
  final String postId;

  const CommentList({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in CommentList: ${snapshot.error}');
          print('Error details:');
          print(snapshot.error.toString());
          if (snapshot.error is FirebaseException) {
            FirebaseException e = snapshot.error as FirebaseException;
            print('Firebase Exception Code: ${e.code}');
            print('Firebase Exception Message: ${e.message}');
          }
          return Center(child: Text('Error loading comments'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return CommentCard(
              content: data['content'] ?? '',
              points: data['points'] ?? 0,
              timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
              commentId: document.id,
              userId: data['userId'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }
}

class CommentCard extends StatelessWidget {
  final String content;
  final int points;
  final DateTime timestamp;
  final String commentId;
  final String userId;

  const CommentCard({
    Key? key,
    required this.content,
    required this.points,
    required this.timestamp,
    required this.commentId,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('$points'),
                    IconButton(
                      icon: Icon(Icons.arrow_upward),
                      onPressed: () {
                        appState.updateCommentPoints(commentId, 1);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_downward),
                      onPressed: () {
                        appState.updateCommentPoints(commentId, -1);
                      },
                    ),
                  ],
                ),
                Text(getRelativeTime(timestamp)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommentInput extends StatefulWidget {
  final String postId;

  const CommentInput({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentInputState createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 20.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: () {
              if (_commentController.text.isNotEmpty) {
                Provider.of<AppState>(context, listen: false).createComment(
                  widget.postId,
                  _commentController.text,
                );
                _commentController.clear();
              }
            },
            child: Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
