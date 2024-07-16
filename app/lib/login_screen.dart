// File: app/lib/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_state.dart';
import 'scuttlebutt_app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userNameController = TextEditingController();
  bool _isCreatingAccount = false;
  String? _userNameError;

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  bool _isValidUserName(String userName) {
    final RegExp validCharacters = RegExp(r'^[a-zA-Z0-9._]+$');
    return validCharacters.hasMatch(userName);
  }

  void _handleSignIn() async {
    try {
      final UserCredential userCredential = await signInWithGoogle();
      final user = userCredential.user;
      if (user != null) {
        final appState = Provider.of<AppState>(context, listen: false);
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['userName'] != null) {
          // Existing user with username, proceed to home page
          await appState.initializeUser(user.uid);
          _navigateToHome();
        } else {
          // New user or existing user without username, show username input
          setState(() {
            _isCreatingAccount = true;
          });
        }
      }
    } catch (e) {
      print('Error during sign in: $e');
      _showErrorDialog('Failed to sign in with Google');
    }
  }

  void _handleCreateAccount() async {
    final userName = _userNameController.text.trim();
    if (!_isValidUserName(userName)) {
      setState(() {
        _userNameError =
            'Letters, numbers, periods, and underscores.';
      });
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final success = await appState.createUserWithUserName(user, userName);
      if (success) {
        _navigateToHome();
      } else {
        setState(() {
          _userNameError = 'Username is already taken. Please choose another.';
        });
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => ScuttlebuttHomePage()),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                'Scuttlebutt',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 50),
              if (!_isCreatingAccount) ...[
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
                  onPressed: _handleSignIn,
                ),
              ] else ...[
                TextField(
                  controller: _userNameController,
                  decoration: InputDecoration(
                    labelText: 'Choose a username',
                    errorText: _userNameError,
                  ),
                  onChanged: (value) {
                    if (_userNameError != null) {
                      setState(() {
                        _userNameError = null;
                      });
                    }
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Create Account'),
                  onPressed: _handleCreateAccount,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
