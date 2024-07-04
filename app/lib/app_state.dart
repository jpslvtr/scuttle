import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppState extends ChangeNotifier {
  String? userId;
  String? command;

  AppState({this.userId, this.command});

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
}
