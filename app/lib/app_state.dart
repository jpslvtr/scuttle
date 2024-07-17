// File: app/lib/app_state.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  String? userId;
  String? command;
  String? userName;
  List<String> savedPosts = [];
  Map<String, int> userVotes = {};
  Map<String, int> userCommentVotes = {};
  String currentFeed = 'All DOD';
  int userPoints = 0; // Placeholder for user points

  AppState({this.userId, this.command, this.userName});

  Future<void> initializeUser(String uid) async {
    userId = uid;
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        command = userData['command'] as String?;
        userName = userData['userName'] as String?;
        savedPosts = List<String>.from(userData['savedPosts'] ?? []);
        userVotes = Map<String, int>.from(userData['votes'] ?? {});
        userCommentVotes =
            Map<String, int>.from(userData['commentVotes'] ?? {});
        userPoints = userData['points'] as int? ?? 0; // Initialize user points
      } else {
        await createUserDocument(uid);
      }
    } catch (e) {
      print('Error fetching or creating user data: $e');
    }
    notifyListeners();
  }

  Future<void> createUserDocument(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': FirebaseAuth.instance.currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'profileEmoji': '🙂',
        'savedPosts': [],
        'userName': '',
        'votes': {},
        'commentVotes': {},
        'points': 0, // Initialize user points
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  void setCurrentFeed(String feed) {
    currentFeed = feed;
    notifyListeners();
  }

  void clearUserData() {
    userId = null;
    command = null;
    userName = null;
    savedPosts.clear();
    userVotes.clear();
    userCommentVotes.clear();
    currentFeed = 'All DOD';
    userPoints = 0;
    notifyListeners();
  }

  Future<bool> isUserNameAvailable(String userName) async {
    if (userName.isEmpty) return true;
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('userName', isEqualTo: userName)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  Future<void> createPost(String title, String content, String feed) async {
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('posts').add({
      'title': title,
      'content': content,
      'userId': userId,
      'userName': userName,
      'command': command,
      'feed': feed,
      'points': 0,
      'commentCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
      'profileEmoji': await getProfileEmoji(),
    });

    notifyListeners();
  }

  Future<String> getProfileEmoji() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return (userDoc.data() as Map<String, dynamic>)['profileEmoji'] ?? '🙂';
  }

  Future<void> updatePostPoints(String postId, int delta) async {
    if (userId == null) return;

    try {
      DocumentReference postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);

      int currentVote = userVotes[postId] ?? 0;
      int newVote = currentVote + delta;

      if (newVote.abs() > 1) {
        print('Cannot vote more than once in each direction');
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot freshPost = await transaction.get(postRef);
        if (!freshPost.exists) {
          throw Exception('Post does not exist!');
        }

        int oldPoints = freshPost.get('points') as int;
        int newPoints = oldPoints + delta;

        transaction.update(postRef, {'points': newPoints});

        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        transaction.update(userRef, {'votes.$postId': newVote});
      });

      userVotes[postId] = newVote;
      notifyListeners();
    } catch (e) {
      print('Error updating post points: $e');
    }
  }

  Future<void> createComment(String postId, String content) async {
    if (userId == null) return;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String currentUserName = userData['userName'] ?? '';
    String currentProfileEmoji = userData['profileEmoji'] ?? '🙂';

    DocumentReference commentRef =
        await FirebaseFirestore.instance.collection('comments').add({
      'postId': postId,
      'userId': userId,
      'userName': currentUserName,
      'profileEmoji': currentProfileEmoji,
      'content': content,
      'points': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });

    notifyListeners();
  }

  Future<void> updateCommentPoints(String commentId, int delta) async {
    if (userId == null) return;

    try {
      DocumentReference commentRef =
          FirebaseFirestore.instance.collection('comments').doc(commentId);

      int currentVote = userCommentVotes[commentId] ?? 0;
      int newVote = currentVote + delta;

      if (newVote.abs() > 1) {
        print('Cannot vote more than once in each direction');
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot freshComment = await transaction.get(commentRef);
        if (!freshComment.exists) {
          throw Exception('Comment does not exist!');
        }

        int oldPoints = freshComment.get('points') as int;
        int newPoints = oldPoints + delta;

        transaction.update(commentRef, {'points': newPoints});

        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        transaction.update(userRef, {'commentVotes.$commentId': newVote});
      });

      userCommentVotes[commentId] = newVote;
      notifyListeners();
    } catch (e) {
      print('Error updating comment points: $e');
    }
  }

  Future<void> deleteAccount() async {
    if (userId == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? userNameToCheck = userData['userName'] as String?;
      bool hadUsername = userNameToCheck != null && userNameToCheck.isNotEmpty;

      if (hadUsername) {
        await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .get()
            .then((snapshot) {
          for (DocumentSnapshot doc in snapshot.docs) {
            doc.reference.update({
              'userName': '[deleted]',
              'profileEmoji': '🫥',
            });
          }
        });

        await FirebaseFirestore.instance
            .collection('comments')
            .where('userId', isEqualTo: userId)
            .get()
            .then((snapshot) {
          for (DocumentSnapshot doc in snapshot.docs) {
            doc.reference.update({
              'userName': '[deleted]',
              'profileEmoji': '🫥',
            });
          }
        });
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      await FirebaseAuth.instance.currentUser?.delete();

      clearUserData();
    } catch (e) {
      print('Error deleting account: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    if (userId == null) return {};

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching user profile: $e');
      return {};
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (userId == null) return;

    try {
      if (data.containsKey('userName')) {
        String newUserName = data['userName'] as String;
        if (newUserName.toLowerCase() == 'anonymous') {
          print('Error: Username "anonymous" is not allowed');
          return;
        }
        if (newUserName.length > 15) {
          print('Error: Username must be 15 characters or less');
          return;
        }
        if (!(await isUserNameAvailable(newUserName))) {
          print('Error: Username is not available');
          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(data);
      if (data.containsKey('userName')) {
        userName = data['userName'];
      }
      notifyListeners();
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    if (userId == null) return;

    try {
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (postDoc.exists) {
        Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
        if (postData['userId'] == userId) {
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .delete();

          QuerySnapshot comments = await FirebaseFirestore.instance
              .collection('comments')
              .where('postId', isEqualTo: postId)
              .get();

          for (DocumentSnapshot commentDoc in comments.docs) {
            await commentDoc.reference.delete();
          }

          notifyListeners();
        } else {
          throw Exception('You do not have permission to delete this post');
        }
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      print('Error deleting post: $e');
      throw e;
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(commentId)
          .delete();

      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });

      notifyListeners();
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

  Future<void> updateProfileEmoji(String emoji) async {
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'profileEmoji': emoji});
      notifyListeners();
    } catch (e) {
      print('Error updating profile emoji: $e');
    }
  }

  Future<void> toggleSavedPost(String postId) async {
    if (userId == null) return;

    try {
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (postDoc.exists) {
        Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
        if (postData['userId'] == userId) {
          print('Cannot save your own post');
          return;
        }
      }

      if (savedPosts.contains(postId)) {
        savedPosts.remove(postId);
      } else {
        savedPosts.insert(0, postId);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'savedPosts': savedPosts});

      notifyListeners();
    } catch (e) {
      print('Error toggling saved post: $e');
    }
  }

  Future<List<DocumentSnapshot>> getSavedPosts() async {
    if (userId == null) return [];

    try {
      List<DocumentSnapshot> savedPostDocs = [];
      for (String postId in savedPosts) {
        DocumentSnapshot postDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .get();
        if (postDoc.exists) {
          savedPostDocs.add(postDoc);
        }
      }
      return savedPostDocs;
    } catch (e) {
      print('Error fetching saved posts: $e');
      return [];
    }
  }
}
