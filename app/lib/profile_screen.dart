// File: app/lib/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'login_screen.dart';
import 'post_detail_screen.dart';
import 'post_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Column(
      children: [
        _buildProfileHeader(appState),
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'My Posts'),
            Tab(text: 'My Comments'),
            Tab(text: 'Saved'),
          ],
          indicatorColor: Colors.blue[800],
          labelColor: Colors.blue[800],
          unselectedLabelColor: Colors.grey,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsList(appState),
              _buildCommentsList(appState),
              _buildSavedPostsList(appState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(AppState appState) {
    return FutureBuilder<Map<String, dynamic>>(
      future: appState.getUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          print('Error in _buildProfileHeader: ${snapshot.error}');
          return Text('Error loading profile: ${snapshot.error}');
        }
        final userData = snapshot.data ?? {};
        final displayName = userData['userName'] == null || userData['userName'].isEmpty
            ? '@anonymous'
            : '@${userData['userName']}';
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[100],
                  border: Border.all(
                    color: Colors.blue[800]!,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    userData['profileEmoji'] ?? '🙂',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Text(
                displayName,
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(width: 16),
             IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 20.0, 
                ),
                onPressed: () => _showEditOptions(context, appState, userData),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditOptions(
      BuildContext context, AppState appState, Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.emoji_emotions),
                title: Text('Change Emoji'),
                onTap: () {
                  Navigator.pop(context);
                  _showEmojiPicker(context, appState);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Set/edit username'),
                onTap: () {
                  Navigator.pop(context);
                  _showUsernameEditor(context, appState, userData['userName']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmojiPicker(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose an emoji'),
          content: Wrap(
            spacing: 10,
            children: [
              '🙂',
              '🙃',
              '😐',
              '😬',
              '🥲',
              '🤔',
              '🤷',
              '🤷‍♀️',
              '🫡',
              '😳',
              '🫣',
              '🙄',
              '🧐',
              '😴',
              '🫥',
              '🫨',
              '💀',
              '🤡',
              '🥸',
              '👾'
            ]
                .map((emoji) => GestureDetector(
                      onTap: () {
                        appState.updateProfileEmoji(emoji);
                        Navigator.of(context).pop();
                      },
                      child: Text(emoji, style: TextStyle(fontSize: 40)),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  void _showUsernameEditor(
      BuildContext context, AppState appState, String? currentUsername) {
    final TextEditingController controller =
        TextEditingController(text: currentUsername);
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Edit Username'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      setState(() {
                        errorText = null;
                      });
                    },
                    maxLength: 15,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Letters, numbers, periods, and underscores. Leave empty for anonymous.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Save'),
                  onPressed: () async {
                    final newUsername = controller.text.trim();
                    if (newUsername.toLowerCase() == 'anonymous') {
                      setState(() {
                        errorText = 'Username "anonymous" is not allowed';
                      });
                    } else if (newUsername.length > 15) {
                      setState(() {
                        errorText = 'Username must be 15 characters or less';
                      });
                    } else if (_isValidUserName(newUsername) ||
                        newUsername.isEmpty) {
                      final isAvailable =
                          await appState.isUserNameAvailable(newUsername);
                      if (isAvailable || newUsername == currentUsername) {
                        await appState
                            .updateUserProfile({'userName': newUsername});
                        Navigator.of(context).pop();
                      } else {
                        setState(() {
                          errorText = 'Username is not available';
                        });
                      }
                    } else {
                      setState(() {
                        errorText = 'Invalid username format';
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isValidUserName(String userName) {
    final RegExp validCharacters = RegExp(r'^[a-zA-Z0-9._]+$');
    return validCharacters.hasMatch(userName);
  }

  Widget _buildPostsList(AppState appState) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: appState.userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in _buildPostsList: ${snapshot.error}');
          return Center(child: Text('Error loading posts: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data!.docs;
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            return PostCard(
              title: post['title'] ?? '',
              content: post['content'] ?? '',
              points: post['points'] ?? 0,
              commentCount: post['commentCount'] ?? 0,
              timestamp: post['timestamp']?.toDate() ?? DateTime.now(),
              postId: posts[index].id,
              userId: post['userId'] ?? '',
            );
          },
        );
      },
    );
  }

  Widget _buildCommentsList(AppState appState) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comments')
          .where('userId', isEqualTo: appState.userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in _buildCommentsList: ${snapshot.error}');
          return Center(
              child: Text('Error loading comments: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final comments = snapshot.data!.docs;
        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index].data() as Map<String, dynamic>;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(comment['postId'])
                  .get(),
              builder: (context, postSnapshot) {
                if (postSnapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(title: Text('Loading...')),
                  );
                }
                if (postSnapshot.hasError) {
                  print(
                      'Error loading post for comment: ${postSnapshot.error}');
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(title: Text('Error loading post')),
                  );
                }
                final postData =
                    postSnapshot.data!.data() as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PostDetailScreen(postId: comment['postId']),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  postData['title'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20),
                                onPressed: () => _showDeleteCommentConfirmation(
                                    context, appState, comment['postId'], comments[index].id),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(postData['userId'])
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text('@loading...');
                              }
                              if (userSnapshot.hasError) {
                                print(
                                    'Error loading user data: ${userSnapshot.error}');
                                return Text('@anonymous');
                              }
                              final userData = userSnapshot.data?.data()
                                  as Map<String, dynamic>?;
                              final userName = userData?['userName'] as String?;
                              return Text(
                                '@${userName?.isNotEmpty == true ? userName : 'anonymous'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 8),
                          Text(
                            comment['content'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.arrow_upward, size: 16),
                                    onPressed: () {
                                      appState.updateCommentPoints(comments[index].id, 1);
                                    },
                                  ),
                                  Text('${comment['points']}',
                                      style: TextStyle(fontSize: 14)),
                                  IconButton(
                                    icon: Icon(Icons.arrow_downward, size: 16),
                                    onPressed: () {
                                      appState.updateCommentPoints(comments[index].id, -1);
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                getRelativeTime(comment['timestamp'].toDate()),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showDeleteCommentConfirmation(BuildContext context, AppState appState, String postId, String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment? This action cannot be undone.'),
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

  Widget _buildSavedPostsList(AppState appState) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: appState.getSavedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('Error in _buildSavedPostsList: ${snapshot.error}');
          return Center(
              child: Text('Error loading saved posts: ${snapshot.error}'));
        }
        final savedPosts = snapshot.data ?? [];
        return ListView.builder(
          itemCount: savedPosts.length,
          itemBuilder: (context, index) {
            final post = savedPosts[index].data() as Map<String, dynamic>;
            return PostCard(
              title: post['title'] ?? '',
              content: post['content'] ?? '',
              points: post['points'] ?? 0,
              commentCount: post['commentCount'] ?? 0,
              timestamp: post['timestamp']?.toDate() ?? DateTime.now(),
              postId: savedPosts[index].id,
              userId: post['userId'] ?? '',
            );
          },
        );
      },
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('App'),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notification options'),
            onTap: () {
              // TODO: Implement notification options
              print('Notification options tapped');
            },
          ),
          _buildSectionHeader('Support'),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy policy'),
            onTap: () {
              // TODO: Show privacy policy
              print('Privacy policy tapped');
            },
          ),
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Terms of Service'),
            onTap: () {
              // TODO: Show Terms of Service
              print('Terms of Service tapped');
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Community guidelines'),
            onTap: () {
              // TODO: Show community guidelines
              print('Community guidelines tapped');
            },
          ),
          ListTile(
            leading: Icon(Icons.bug_report),
            title: Text('Report a bug'),
            onTap: () {
              // TODO: Implement bug reporting
              print('Report a bug tapped');
            },
          ),
          ListTile(
            leading: Icon(Icons.contact_support),
            title: Text('Contact us'),
            onTap: () {
              // TODO: Implement contact functionality
              print('Contact us tapped');
            },
          ),
          _buildSectionHeader('Account'),
          ListTile(
            leading: Icon(Icons.corporate_fare),
            title: Text('Change commands'),
            onTap: () {
              // TODO: Implement change commands functionality
              print('Change commands tapped');
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Log Out'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Provider.of<AppState>(context, listen: false).clearUserData();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              _showDeleteAccountConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await Provider.of<AppState>(context, listen: false)
                      .deleteAccount();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Account deleted successfully')),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  print('Error deleting account: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
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
  } else if (difference.inDays < 30) {
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '$months month${months == 1 ? '' : 's'} ago';
  } else {
    final years = (difference.inDays / 365).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }
}
