// File: app/lib/app_state.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  String? userId;
  String? command;
  String? userName;
  Set<String> savedPosts = {};

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
        savedPosts = Set<String>.from(userData['savedPosts'] ?? []);
      } else {
        // Create a new user document if it doesn't exist
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
        'profileEmoji': '🙂', // Default emoji
        'savedPosts': [],
        'userName': '', // Set default username to empty string
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  void clearUserData() {
    userId = null;
    command = null;
    userName = null;
    savedPosts.clear();
    notifyListeners();
  }

  Future<bool> isUserNameAvailable(String userName) async {
    if (userName.isEmpty) return true; // Allow empty usernames
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
      'command': command,
      'feed': feed,
      'points': 0,
      'commentCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });

    notifyListeners();
  }

  Future<void> updatePostPoints(String postId, int delta) async {
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'points': FieldValue.increment(delta),
    });

    notifyListeners();
  }

  Future<void> createComment(String postId, String content) async {
    if (userId == null) return;

    DocumentReference commentRef =
        await FirebaseFirestore.instance.collection('comments').add({
      'postId': postId,
      'userId': userId,
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

    await FirebaseFirestore.instance
        .collection('comments')
        .doc(commentId)
        .update({
      'points': FieldValue.increment(delta),
    });

    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      QuerySnapshot posts = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      for (DocumentSnapshot doc in posts.docs) {
        await doc.reference.delete();
      }

      QuerySnapshot comments = await FirebaseFirestore.instance
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();
      for (DocumentSnapshot doc in comments.docs) {
        await doc.reference.delete();
      }

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
      if (savedPosts.contains(postId)) {
        savedPosts.remove(postId);
      } else {
        savedPosts.add(postId);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'savedPosts': savedPosts.toList()});

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
