// File: app/lib/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
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

  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    } catch (e) {
      print('Error in signInWithApple: $e');
      return null;
    }
  }

  void _handleSignIn(Future<UserCredential?> Function() signInMethod) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential? userCredential = await signInMethod();
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
        throw Exception('Failed to sign in');
      }
    } catch (e) {
      print('Error during sign in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in: $e')),
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
              _buildSignInButton(
                onPressed:
                    _isLoading ? null : () => _handleSignIn(signInWithGoogle),
                icon: Image.asset(
                  'assets/google_logo.png',
                  height: 24.0,
                ),
                text: 'Sign in with Google',
              ),
              SizedBox(height: 20),
              FutureBuilder<bool>(
                future: SignInWithApple.isAvailable(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return _buildSignInButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleSignIn(signInWithApple),
                      icon: Icon(Icons.apple, size: 24, color: Colors.black),
                      text: 'Sign in with Apple',
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: _isLoading
            ? CircularProgressIndicator()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  SizedBox(width: 10),
                  Text(text),
                ],
              ),
      ),
    );
  }
}
