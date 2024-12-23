import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'post_card.dart';

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
                    print('Error in PostDetailScreen: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic> postData =
                      snapshot.data!.data() as Map<String, dynamic>;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(postData['userId'])
                        .get(),
                    builder: (context, userSnapshot) {
                      String userName = '@anonymous';
                      String profileEmoji = '🫥';
                      if (userSnapshot.connectionState ==
                          ConnectionState.done) {
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data()
                              as Map<String, dynamic>?;
                          userName = userData?['userName'] as String? ?? '';
                          profileEmoji =
                              userData?['profileEmoji'] as String? ?? '🫥';
                          if (userName.isEmpty) {
                            userName = '@anonymous';
                          } else {
                            userName = '@$userName';
                          }
                        } else {
                          userName = '@[deleted]';
                        }
                      }

                      return ListView(
                        padding: EdgeInsets.all(16.0),
                        children: [
                          Text(
                            'Feed: ${postData['feed'] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          SizedBox(height: 8),
                          PostCard(
                            title: postData['title'] ?? '',
                            content: postData['content'] ?? '',
                            commentCount: postData['commentCount'] ?? 0,
                            timestamp: postData['timestamp']?.toDate() ??
                                DateTime.now(),
                            postId: postId,
                            userId: postData['userId'] ?? '',
                            profileEmoji: profileEmoji,
                            userName: userName,
                            isDetailView: true,
                            imageUrl: postData['imageUrl'],
                          ),
                          Divider(),
                          Text(
                            'Comments',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          CommentList(postId: postId),
                        ],
                      );
                    },
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

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Hero(
            tag: imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
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
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in CommentList: ${snapshot.error}');
          return Center(child: Text('Error loading comments'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final commentDocs = snapshot.data!.docs;

        // Sort comments by points (votes) in descending order
        commentDocs.sort((a, b) {
          final aPoints =
              (a.data() as Map<String, dynamic>)['points'] as int? ?? 0;
          final bPoints =
              (b.data() as Map<String, dynamic>)['points'] as int? ?? 0;
          return bPoints.compareTo(aPoints);
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: commentDocs.length,
          itemBuilder: (context, index) {
            final commentDoc = commentDocs[index];
            final commentData = commentDoc.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(commentData['userId'])
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

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

                return CommentCard(
                  content: commentData['content'] ?? '',
                  timestamp:
                      commentData['timestamp']?.toDate() ?? DateTime.now(),
                  commentId: commentDoc.id,
                  userId: commentData['userId'] ?? '',
                  postId: postId,
                  userName: userName,
                  profileEmoji: profileEmoji,
                );
              },
            );
          },
        );
      },
    );
  }
}

class CommentCard extends StatelessWidget {
  final String content;
  final DateTime timestamp;
  final String commentId;
  final String userId;
  final String postId;
  final String userName;
  final String profileEmoji;

  const CommentCard({
    Key? key,
    required this.content,
    required this.timestamp,
    required this.commentId,
    required this.userId,
    required this.postId,
    required this.userName,
    required this.profileEmoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(profileEmoji),
                    SizedBox(width: 4),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (userId == appState.userId)
                  IconButton(
                    icon: Icon(Icons.delete, size: 20),
                    onPressed: () =>
                        _showDeleteCommentConfirmation(context, appState),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
            SizedBox(height: 4),
            Text(content),
            SizedBox(height: 4),
            StreamBuilder<DocumentSnapshot>(
              stream: appState.getCommentStream(commentId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                final commentData =
                    snapshot.data!.data() as Map<String, dynamic>;
                final points = commentData['points'] as int? ?? 0;
                final currentVote = appState.userCommentVotes[commentId] ?? 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_upward,
                            size: 16,
                            color: currentVote == 1 ? Colors.orange : null,
                          ),
                          onPressed: () {
                            appState.updateCommentPoints(commentId, 1);
                          },
                        ),
                        Text('$points', style: TextStyle(fontSize: 12)),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_downward,
                            size: 16,
                            color: currentVote == -1 ? Colors.blue : null,
                          ),
                          onPressed: () {
                            appState.updateCommentPoints(commentId, -1);
                          },
                        ),
                      ],
                    ),
                    Text(
                      getRelativeTime(timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCommentConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Comment'),
          content: Text(
              'Are you sure you want to delete this comment? This action cannot be undone.'),
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
                appState.deleteComment(postId, commentId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
    return '${difference.inMinutes} min';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hr';
  } else {
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
  }
}
