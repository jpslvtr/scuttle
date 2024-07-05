import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_state.dart';
import 'scuttlebutt_app.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scuttlebutt',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/google_logo.png',
                    height: 24.0,
                  ),
                  SizedBox(width: 10),
                  Text('Sign in with Google'),
                ],
              ),
              onPressed: () async {
                try {
                  final UserCredential userCredential =
                      await signInWithGoogle();
                  final user = userCredential.user;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .set({
                      'email': user.email,
                      'displayName': user.displayName,
                      'createdAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    await Provider.of<AppState>(context, listen: false)
                        .initializeUser(user.uid);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => ScuttlebuttHomePage()),
                    );
                  }
                } catch (e) {
                  print('Error during sign in: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to sign in with Google')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
