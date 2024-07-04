import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  String? userId;
  String? command;

  AppState({this.userId, this.command});

  Future<void> initializeUser(String uid) async {
    userId = uid;
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        command = userData['command'] as String?;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    notifyListeners();
  }

  void clearUserData() {
    userId = null;
    command = null;
    notifyListeners();
  }

  Future<void> createPost(String content) async {
    if (userId == null || command == null) return;

    await FirebaseFirestore.instance.collection('posts').add({
      'content': content,
      'userId': userId,
      'command': command,
      'upvotes': 0,
      'downvotes': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });

    notifyListeners();
  }

  Future<void> upvotePost(String postId) async {
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'upvotes': FieldValue.increment(1),
    });

    notifyListeners();
  }

  Future<void> downvotePost(String postId) async {
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'downvotes': FieldValue.increment(1),
    });

    notifyListeners();
  }

  Future<void> updateUserCommand(String newCommand) async {
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'command': newCommand,
    });

    command = newCommand;
    notifyListeners();
  }

  Future<void> createComment(String postId, String content) async {
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('comments').add({
      'postId': postId,
      'userId': userId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
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

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update(data);
    notifyListeners();
  }
}
