// File: app/lib/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'scuttlebutt_app.dart';
import 'zone_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        throw Exception('Google Sign In was canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential;
    } catch (e) {
      print('Error in signInWithGoogle: $e');
      return null;
    }
  }

  void _handleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential? userCredential = await signInWithGoogle();
      if (userCredential != null && userCredential.user != null && mounted) {
        final user = userCredential.user!;
        final appState = Provider.of<AppState>(context, listen: false);

        // Check if the user document already exists
        bool userExists = await appState.checkUserExists(user.uid);

        if (!userExists) {
          // Create user document in Firestore
          await appState.createUserDocument(user.uid);
        }

        // Initialize user data
        await appState.initializeUser(user.uid);

        // Navigate to ZoneSelectionScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ZoneSelectionScreen(isInitialSetup: true),
          ),
        );
      } else {
        throw Exception('Failed to sign in with Google');
      }
    } catch (e) {
      print('Error during sign in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in with Google: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToZoneSelection() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => ZoneSelectionScreen(isInitialSetup: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Scuttle',
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
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Row(
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
                onPressed: _isLoading ? null : _handleSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
