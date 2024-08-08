import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'post_detail_screen.dart';

class PostCard extends StatelessWidget {
  final String title;
  final String content;
  final int points;
  final int commentCount;
  final DateTime timestamp;
  final String postId;
  final String userId;
  final String profileEmoji;
  final String userName;
  final bool isDetailView;

  const PostCard({
    Key? key,
    required this.title,
    required this.content,
    required this.points,
    required this.commentCount,
    required this.timestamp,
    required this.postId,
    required this.userId,
    required this.profileEmoji,
    required this.userName,
    this.isDetailView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isCreator = appState.userId == userId;
    final isSaved = appState.savedPosts.contains(postId);
    final userVote = appState.userVotes[postId] ?? 0;

    return Card(
      margin: EdgeInsets.all(8.0),
      child: InkWell(
        onTap: isDetailView
            ? null
            : () {
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(profileEmoji),
                        SizedBox(width: 4),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          getRelativeTime(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCreator && !isDetailView)
                    IconButton(
                      icon: Icon(Icons.delete, size: 20),
                      onPressed: () => _showDeleteConfirmation(context),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      alignment: Alignment.centerRight,
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color: userVote == 1 ? Colors.orange : null,
                        ),
                        onPressed: () {
                          appState.updatePostPoints(postId, 1);
                        },
                      ),
                      Text('$points'),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: userVote == -1 ? Colors.blue : null,
                        ),
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
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? Colors.grey[700] : null,
                    ),
                    onPressed: () {
                      appState.toggleSavedPost(postId);
                    },
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
    return '${difference.inMinutes} min';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hr';
  } else if (difference.inDays < 30) {
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '$months month${months == 1 ? '' : 's'}';
  } else {
    final years = (difference.inDays / 365).floor();
    return '$years year${years == 1 ? '' : 's'}';
  }
}
