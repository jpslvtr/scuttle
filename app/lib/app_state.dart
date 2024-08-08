import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AppState extends ChangeNotifier {
  String? userId;
  String? command;
  String? userName;
  List<String> savedPosts = [];
  Map<String, int> userVotes = {};
  Map<String, int> userCommentVotes = {};
  String currentFeed = 'All Navy';
  int userPoints = 0;
  Position? userLocation;
  bool isLocationDenied = false;
  bool isOutOfZone = false;
  bool isNewUser = true;
  bool isLocationPermissionChecked = false;

  static const Map<String, Map<String, dynamic>> zones = {
    'TEST: Bay Area': {
      'center': {'lat': 37.7749, 'lng': -122.4194},
      'radius': 80467
    },
    'Norfolk': {
      'center': {'lat': 36.8508, 'lng': -76.2859},
      'radius': 120700
    },
    'San Diego': {
      'center': {'lat': 32.7157, 'lng': -117.1611},
      'radius': 160934
    },
    'Jacksonville': {
      'center': {'lat': 30.3322, 'lng': -81.6557},
      'radius': 120700
    },
    'Pensacola': {
      'center': {'lat': 30.4213, 'lng': -87.2169},
      'radius': 160934
    },
    'Pacific Northwest': {
      'center': {'lat': 47.6062, 'lng': -122.3321},
      'radius': 160934
    },
    'Japan': {
      'center': {'lat': 35.6762, 'lng': 139.6503},
      'radius': 804672
    },
    'Hawaii': {
      'center': {'lat': 21.3069, 'lng': -157.8583},
      'radius': 321869
    },
    'National Capital Region': {
      'center': {'lat': 38.9072, 'lng': -77.0369},
      'radius': 160934
    },
  };

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
        userPoints = userData['points'] as int? ?? 0;
        isNewUser = false;
      } else {
        await createUserDocument(uid);
      }
      await recalculateUserPoints();
    } catch (e) {
      print('Error initializing user: $e');
      await createUserDocument(uid);
    }
    notifyListeners();
  }

  Future<void> createUserDocument(String uid) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'profileEmoji': '🙂',
        'savedPosts': [],
        'userName': '',
        'votes': {},
        'commentVotes': {},
        'points': 0,
        'command': null,
      }, SetOptions(merge: true));
      isNewUser = true;
      notifyListeners();
    } catch (e) {
      print('Error creating user document: $e');
      throw e;
    }
  }

  Future<void> updateUserPoints(int delta) async {
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        DocumentSnapshot userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User document does not exist!');
        }

        int currentPoints = userDoc.get('points') as int? ?? 0;
        int newPoints = (currentPoints + delta).clamp(0, 999);

        transaction.update(userRef, {'points': newPoints});

        userPoints = newPoints;
      });
      notifyListeners();
    } catch (e) {
      print('Error updating user points: $e');
    }
  }

  Future<void> recalculateUserPoints() async {
    if (userId == null) return;

    try {
      int totalPoints = 0;

      // Calculate points from posts (1 point per post)
      QuerySnapshot postsDocs = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      totalPoints += postsDocs.docs.length;

      // Calculate points from comments (1 point per comment)
      QuerySnapshot commentsDocs = await FirebaseFirestore.instance
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();
      totalPoints += commentsDocs.docs.length;

      // Calculate points from post upvotes (1 point per upvote)
      for (var post in postsDocs.docs) {
        int postPoints =
            (post.data() as Map<String, dynamic>)['points'] as int? ?? 0;
        totalPoints += postPoints.clamp(0, 5); // Cap points per post at 5
      }

      // Calculate points from comment upvotes (1 point per upvote)
      for (var comment in commentsDocs.docs) {
        int commentPoints =
            (comment.data() as Map<String, dynamic>)['points'] as int? ?? 0;
        totalPoints += commentPoints.clamp(0, 3); // Cap points per comment at 3
      }

      // Cap total points at 999
      totalPoints = totalPoints.clamp(0, 999);

      // Set the calculated points
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'points': totalPoints});

      userPoints = totalPoints;
      notifyListeners();
    } catch (e) {
      print('Error recalculating user points: $e');
    }
  }

  Future<void> calculateAndSetInitialPoints() async {
    if (userId == null) return;

    try {
      int totalPoints = 0;

      // Calculate points from posts
      QuerySnapshot postsDocs = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      totalPoints += postsDocs.docs.length * 2;

      // Calculate points from comments
      QuerySnapshot commentsDocs = await FirebaseFirestore.instance
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();
      totalPoints += commentsDocs.docs.length;

      // Calculate points from post votes
      for (var post in postsDocs.docs) {
        totalPoints +=
            (post.data() as Map<String, dynamic>)['points'] as int? ?? 0;
      }

      // Calculate points from comment votes
      for (var comment in commentsDocs.docs) {
        totalPoints +=
            (comment.data() as Map<String, dynamic>)['points'] as int? ?? 0;
      }

      // Set the calculated points
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'points': totalPoints});

      userPoints = totalPoints;
      notifyListeners();
    } catch (e) {
      print('Error calculating initial points: $e');
    }
  }
  
  Future<bool> checkUserExists(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.exists;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  Future<void> setLocationPermissionChecked(bool checked) async {
    isLocationPermissionChecked = checked;
    notifyListeners();
  }

  Future<void> setUserLocation(Position position) async {
    userLocation = position;
    notifyListeners();
  }

  String? getRecommendedZone() {
    if (userLocation == null) return null;

    String? closestZone;
    double minDistance = double.infinity;

    for (var entry in zones.entries) {
      var zone = entry.value;
      var center = zone['center'];
      var zoneRadius = zone['radius'];

      double distance = Geolocator.distanceBetween(
        userLocation!.latitude,
        userLocation!.longitude,
        center['lat'],
        center['lng'],
      );

      if (distance < minDistance && distance <= zoneRadius) {
        minDistance = distance;
        closestZone = entry.key;
      }
    }

    return closestZone;
  }

  Future<void> setUserCommand(String? newCommand) async {
    command = newCommand;
    currentFeed = newCommand ?? 'All Navy';
    isOutOfZone = newCommand == null;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'command': newCommand});
      notifyListeners();
    } catch (e) {
      print('Error updating user command: $e');
    }
  }

  void setLocationDenied(bool denied) {
    isLocationDenied = denied;
    notifyListeners();
  }

  void setCurrentFeed(String feed) {
    if (feed == 'All Navy' || feed == command) {
      currentFeed = feed;
      notifyListeners();
    }
  }

  List<String> getAvailableFeeds() {
    if (command != null) {
      return ['All Navy', command!];
    } else {
      return ['All Navy'];
    }
  }

  void clearUserData() {
    userId = null;
    command = null;
    userName = null;
    savedPosts.clear();
    userVotes.clear();
    userCommentVotes.clear();
    currentFeed = 'All Navy';
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

  Stream<QuerySnapshot> getPostsStream(String currentFeed) {
    Query query;
    if (currentFeed == 'All Navy') {
      query = FirebaseFirestore.instance
          .collection('posts')
          .where('feed', isEqualTo: 'All Navy');
    } else {
      query = FirebaseFirestore.instance
          .collection('posts')
          .where('feed', isEqualTo: currentFeed);
    }
    return query.orderBy('timestamp', descending: true).limit(50).snapshots();
  }

  Stream<DocumentSnapshot> getPostStream(String postId) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .snapshots();
  }

  Stream<DocumentSnapshot> getCommentStream(String commentId) {
    return FirebaseFirestore.instance
        .collection('comments')
        .doc(commentId)
        .snapshots();
  }

  Future<void> updatePostPoints(String postId, int delta) async {
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference postRef =
            FirebaseFirestore.instance.collection('posts').doc(postId);
        DocumentSnapshot freshPost = await transaction.get(postRef);

        if (!freshPost.exists) {
          throw Exception('Post does not exist!');
        }

        int currentVote = userVotes[postId] ?? 0;
        int newVote;

        if (currentVote == delta) {
          newVote = 0;
          delta = -currentVote;
        } else {
          newVote = delta;
          delta = newVote - currentVote;
        }

        int oldPoints = freshPost.get('points') as int;
        int newPoints = oldPoints + delta;

        // Read user document
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        DocumentSnapshot userDoc = await transaction.get(userRef);

        // Read post creator document
        String postCreatorId = freshPost.get('userId') as String;
        DocumentReference postCreatorRef =
            FirebaseFirestore.instance.collection('users').doc(postCreatorId);
        DocumentSnapshot postCreatorDoc = await transaction.get(postCreatorRef);

        // Perform all writes after reads
        transaction.update(postRef, {'points': newPoints});
        transaction.update(userRef, {'votes.$postId': newVote});

        // Update post creator's points if the user exists
        if (postCreatorDoc.exists && postCreatorId != userId) {
          int creatorPoints = postCreatorDoc.get('points') as int? ?? 0;
          transaction.update(postCreatorRef, {'points': creatorPoints + delta});
        }

        // Update local state
        userVotes[postId] = newVote;
      });
    } catch (e) {
      print('Error updating post points: $e');
    }
  }

  Future<void> updateCommentPoints(String commentId, int delta) async {
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference commentRef =
            FirebaseFirestore.instance.collection('comments').doc(commentId);
        DocumentSnapshot freshComment = await transaction.get(commentRef);

        if (!freshComment.exists) {
          throw Exception('Comment does not exist!');
        }

        int currentVote = userCommentVotes[commentId] ?? 0;
        int newVote;
        int pointsDelta;

        if (currentVote == delta) {
          // If the user is voting the same way, remove their vote
          newVote = 0;
          pointsDelta = -currentVote;
        } else if (currentVote == 0) {
          // If the user hasn't voted before, add their vote
          newVote = delta;
          pointsDelta = delta;
        } else {
          // If the user is changing their vote, update accordingly
          newVote = delta;
          pointsDelta = delta *
              2; // Multiply by 2 to reverse previous vote and add new vote
        }

        int oldPoints = freshComment.get('points') as int;
        int newPoints = oldPoints + pointsDelta;

        // Perform all reads before writes
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        DocumentSnapshot userDoc = await transaction.get(userRef);

        String commentCreatorId = freshComment.get('userId') as String;
        DocumentReference commentCreatorRef = FirebaseFirestore.instance
            .collection('users')
            .doc(commentCreatorId);
        DocumentSnapshot commentCreatorDoc =
            await transaction.get(commentCreatorRef);

        // Now perform all writes
        transaction.update(commentRef, {'points': newPoints});
        transaction.update(userRef, {'commentVotes.$commentId': newVote});

        // Update comment creator's points if the user exists and it's not the current user
        if (commentCreatorDoc.exists && commentCreatorId != userId) {
          int creatorPoints = commentCreatorDoc.get('points') as int? ?? 0;
          transaction.update(
              commentCreatorRef, {'points': creatorPoints + pointsDelta});
        }

        // Update local state
        userCommentVotes[commentId] = newVote;
      });
    } catch (e) {
      print('Error updating comment points: $e');
    }
  }

  Future<void> createPost(String title, String content, String feed) async {
    if (userId == null) return;

    String postFeed = feed == 'All Navy' ? 'All Navy' : command ?? '';

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String currentUserName = userData['userName'] as String? ?? '';
    String currentProfileEmoji = userData['profileEmoji'] as String? ?? '🙂';

    await FirebaseFirestore.instance.collection('posts').add({
      'title': title,
      'content': content,
      'userId': userId,
      'userName': currentUserName,
      'command': command,
      'feed': postFeed,
      'points': 0,
      'commentCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
      'profileEmoji': currentProfileEmoji,
    });

    // Award 1 point for creating a post
    await updateUserPoints(1);

    notifyListeners();
  }

  Future<void> createComment(String postId, String content) async {
    if (userId == null) return;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String currentUserName = userData['userName'] as String? ?? '';
    String currentProfileEmoji = userData['profileEmoji'] as String? ?? '🙂';

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

    // Award 1 point for creating a comment
    await updateUserPoints(1);

    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (userId == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document does not exist');
      }

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

      if (!userDoc.exists) {
        await createUserDocument(userId!);
        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
      }

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

        // Update posts
        QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .get();

        WriteBatch batch = FirebaseFirestore.instance.batch();

        for (DocumentSnapshot doc in postsSnapshot.docs) {
          batch.update(doc.reference, {'userName': newUserName});
        }

        // Update comments
        QuerySnapshot commentsSnapshot = await FirebaseFirestore.instance
            .collection('comments')
            .where('userId', isEqualTo: userId)
            .get();

        for (DocumentSnapshot doc in commentsSnapshot.docs) {
          batch.update(doc.reference, {'userName': newUserName});
        }

        // Update user document
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        batch.update(userRef, data);

        // Commit the batch
        await batch.commit();

        // Update local state
        userName = newUserName;
      } else {
        // If we're not updating the username, just update the user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update(data);
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
          // Delete the post
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .delete();

          // Delete all comments associated with the post
          QuerySnapshot comments = await FirebaseFirestore.instance
              .collection('comments')
              .where('postId', isEqualTo: postId)
              .get();

          for (DocumentSnapshot commentDoc in comments.docs) {
            await commentDoc.reference.delete();
          }

          // Remove the post from saved posts of all users
          QuerySnapshot usersWithSavedPost = await FirebaseFirestore.instance
              .collection('users')
              .where('savedPosts', arrayContains: postId)
              .get();

          for (DocumentSnapshot userDoc in usersWithSavedPost.docs) {
            List<String> savedPosts = List<String>.from(userDoc['savedPosts']);
            savedPosts.remove(postId);
            await userDoc.reference.update({'savedPosts': savedPosts});
          }

          // Update local state
          if (savedPosts.contains(postId)) {
            savedPosts.remove(postId);
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

      // Use batched reads to fetch all saved posts at once
      final batches = <Future<List<DocumentSnapshot>>>[];
      for (var i = 0; i < savedPosts.length; i += 10) {
        final end = (i + 10 < savedPosts.length) ? i + 10 : savedPosts.length;
        final batch = FirebaseFirestore.instance
            .collection('posts')
            .where(FieldPath.documentId, whereIn: savedPosts.sublist(i, end))
            .get()
            .then((snapshot) => snapshot.docs);
        batches.add(batch);
      }

      final results = await Future.wait(batches);
      for (var batch in results) {
        savedPostDocs.addAll(batch);
      }

      // Sort the posts to match the order in savedPosts
      savedPostDocs.sort((a, b) =>
          savedPosts.indexOf(a.id).compareTo(savedPosts.indexOf(b.id)));

      return savedPostDocs;
    } catch (e) {
      print('Error fetching saved posts: $e');
      return [];
    }
  }

  Future<Map<String, Map<String, dynamic>>> getUsersData(
      List<String> userIds) async {
    final uniqueUserIds = userIds.toSet().toList();
    final Map<String, Map<String, dynamic>> usersData = {};

    try {
      final batches = <Future<List<DocumentSnapshot>>>[];
      for (var i = 0; i < uniqueUserIds.length; i += 10) {
        final end =
            (i + 10 < uniqueUserIds.length) ? i + 10 : uniqueUserIds.length;
        final batch = FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: uniqueUserIds.sublist(i, end))
            .get()
            .then((snapshot) => snapshot.docs);
        batches.add(batch);
      }

      final results = await Future.wait(batches);
      for (var batch in results) {
        for (var doc in batch) {
          usersData[doc.id] = doc.data() as Map<String, dynamic>;
        }
      }

      return usersData;
    } catch (e) {
      print('Error fetching users data: $e');
      return {};
    }
  }
}
