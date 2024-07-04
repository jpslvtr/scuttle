// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:crypto/crypto.dart';
// import 'dart:convert';
// import 'dart:math';
// import 'app_state.dart';
// import 'scuttlebutt_app.dart';

// class LoginPage extends StatelessWidget {
//   const LoginPage({Key? key}) : super(key: key);

//   String generateNonce([int length = 32]) {
//     final charset =
//         '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
//     final random = Random.secure();
//     return List.generate(length, (_) => charset[random.nextInt(charset.length)])
//         .join();
//   }

//   String sha256ofString(String input) {
//     final bytes = utf8.encode(input);
//     final digest = sha256.convert(bytes);
//     return digest.toString();
//   }

//   Future<UserCredential> signInWithGoogle() async {
//     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//     final GoogleSignInAuthentication? googleAuth =
//         await googleUser?.authentication;
//     final credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth?.accessToken,
//       idToken: googleAuth?.idToken,
//     );
//     final UserCredential userCredential =
//         await FirebaseAuth.instance.signInWithCredential(credential);
//     final String? email = userCredential.user?.email;
//     if (email != null) {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userCredential.user!.uid)
//           .set({'email': email}, SetOptions(merge: true));
//     }
//     return userCredential;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'Scuttlebutt',
//                 style: TextStyle(
//                   fontSize: 48,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF8C1515),
//                 ),
//               ),
//               SizedBox(height: 20),
//               // Image.asset(
//               //   'assets/AppIcon-1024.png',
//               //   width: 100,
//               //   height: 100,
//               // ),
//               SizedBox(height: 50),
//               Container(
//                 width: 250,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.black,
//                     backgroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Image.asset('assets/google_logo.png', height: 24),
//                       SizedBox(width: 10),
//                       Text('Sign in with Google'),
//                     ],
//                   ),
//                   onPressed: () async {
//                     try {
//                       final UserCredential userCredential =
//                           await signInWithGoogle();
//                       final user = userCredential.user;
//                       if (user != null) {
//                         print('User signed in: ${user.uid}');
//                         await Provider.of<AppState>(context, listen: false)
//                             .initializeUser(user.uid)
//                             .catchError((error) {
//                           print('Error initializing user: $error');
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                                 content: Text(
//                                     'Error loading user data. Please try again.')),
//                           );
//                         });
//                         print('UserId set in AppState');
//                         Navigator.of(context).pushReplacement(
//                           MaterialPageRoute(
//                               builder: (context) => PlaceTrackerApp()),
//                         );
//                       }
//                     } catch (e) {
//                       print('Error during sign in: $e');
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                             content: Text('Failed to sign in with Google')),
//                       );
//                     }
//                   },
//                 ),
//               ),
//               SizedBox(height: 20),
//               Container(
//                 width: 250,
//                 height: 50,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     backgroundColor: Colors.black,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.apple, size: 24),
//                       SizedBox(width: 10),
//                       Text(
//                         'Sign in with Apple',
//                         style: TextStyle(
//                           fontSize: Theme.of(context)
//                                   .textTheme
//                                   .labelLarge!
//                                   .fontSize! * 1.05,
//                         ),
//                       ),
//                     ],
//                   ),
//                   onPressed: () async {
//                     final rawNonce = generateNonce();
//                     final nonce = sha256ofString(rawNonce);

//                     try {
//                       final appleCredential =
//                           await SignInWithApple.getAppleIDCredential(
//                         scopes: [
//                           AppleIDAuthorizationScopes.email,
//                           AppleIDAuthorizationScopes.fullName,
//                         ],
//                         nonce: nonce,
//                       );

//                       final oauthCredential =
//                           OAuthProvider("apple.com").credential(
//                         idToken: appleCredential.identityToken,
//                         rawNonce: rawNonce,
//                       );

//                       final userCredential = await FirebaseAuth.instance
//                           .signInWithCredential(oauthCredential);
//                       final user = userCredential.user;

//                       if (user != null) {
//                         print('User signed in with Apple: ${user.uid}');
//                         await Provider.of<AppState>(context, listen: false)
//                             .handleAppleSignIn(userCredential)
//                             .catchError((error) {
//                           print('Error initializing user: $error');
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                                 content: Text(
//                                     'Error loading user data. Please try again.')),
//                           );
//                         });
//                         print('UserId set in AppState');
//                         Navigator.of(context).pushReplacement(
//                           MaterialPageRoute(
//                               builder: (context) => PlaceTrackerApp()),
//                         );
//                       }
//                     } catch (e) {
//                       print('Error during Apple sign in: $e');
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Failed to sign in with Apple')),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
