import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'app_state.dart';
import 'zone_selection_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<UserCredential?> signInWithIdMe() async {
    print("Starting ID.me sign-in process");
    const String clientId = '0d399b555eb4574e6b761b7d2c103662';
    const String redirectUri = 'com.park.scuttle://callback';
    const String authorizationEndpoint = 'https://api.id.me/oauth/authorize';

    final String codeVerifier = _generateRandomString(128);
    final List<int> bytes = utf8.encode(codeVerifier);
    final Digest digest = sha256.convert(bytes);
    final String codeChallenge =
        base64Url.encode(digest.bytes).replaceAll('=', '');

    final String authorizationUrl = '$authorizationEndpoint'
        '?client_id=$clientId'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&response_type=code'
        '&scope=military'
        '&code_challenge=$codeChallenge'
        '&code_challenge_method=S256'
        '&show_verify=true';

    try {
      print("Initiating ID.me authentication");
      print("Authorization URL: $authorizationUrl");

      final result = await FlutterWebAuth.authenticate(
          url: authorizationUrl, callbackUrlScheme: "com.park.scuttle");

      print("Received result from FlutterWebAuth: $result");

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];

      if (error != null) {
        print("Error returned from ID.me: $error");
        print("Error description: $errorDescription");
        throw Exception('Error during ID.me authorization: $error');
      }

      if (code == null) {
        print("No code found in the redirect URI");
        print("Redirect URI parameters: ${uri.queryParameters}");
        throw Exception('No code returned from ID.me');
      }

      print("Authorization code received: $code");

      print("Exchanging authorization code for access token");
      final tokenResponse = await http.post(
        Uri.parse('https://api.id.me/oauth/token'),
        body: {
          'code': code,
          'client_id': clientId,
          'client_secret': 'ca870bd28dbb2d711cc7cef8dc267127',
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
          'code_verifier': codeVerifier,
        },
      );

      print("Token response status code: ${tokenResponse.statusCode}");
      print("Token response body: ${tokenResponse.body}");

      if (tokenResponse.statusCode == 200) {
        print("Access token obtained successfully");
        final tokenData = json.decode(tokenResponse.body);
        final accessToken = tokenData['access_token'];

        print("Calling Firebase Function");
        final callable =
            FirebaseFunctions.instance.httpsCallable('createFirebaseToken');
        final result = await callable.call({'idmeToken': accessToken});

        print("Firebase Function result: ${result.data}");

        final customToken = result.data['customToken'];

        print("Firebase custom token obtained");
        final userCredential =
            await FirebaseAuth.instance.signInWithCustomToken(customToken);

        print("Signed in to Firebase successfully");
        await Provider.of<AppState>(context, listen: false)
            .setIdMeVerified(true);

        return userCredential;
      } else {
        print(
            "Failed to obtain access token. Status code: ${tokenResponse.statusCode}");
        print("Response body: ${tokenResponse.body}");
        throw Exception('Failed to obtain access token');
      }
    } catch (e) {
      print("Error during ID.me sign-in: $e");
      if (e is FirebaseFunctionsException) {
        print("Firebase Functions Exception: ${e.code} - ${e.message}");
        print("Firebase Functions Exception details: ${e.details}");
        if (e.code == 'permission-denied') {
          if (e.message!.contains('not verified by ID.me')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Your ID.me account is not verified. Please verify your account with ID.me and try again.')),
            );
          } else if (e.message!.contains('does not have military status')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'You must have a verified military status with ID.me to use this app.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'You do not have permission to use this app. Please ensure you have a verified military status with ID.me.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('An error occurred during sign-in: ${e.message}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'An unexpected error occurred during sign-in. Please try again.')),
        );
      }
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailPassword() async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      return userCredential;
    } catch (e) {
      print('Error during email/password sign in: $e');
      return null;
    }
  }

  String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
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

        bool userExists = await appState.checkUserExists(user.uid);

        if (!userExists) {
          await appState.createUserDocument(user.uid);
        }

        await appState.initializeUser(user.uid);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/AppIcon-1024-Transparent.png',
                    height: 64,
                    width: 64,
                  ),
                  Text(
                    'Scuttle',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50),
              _buildSignInButton(
                onPressed:
                    _isLoading ? null : () => _handleSignIn(signInWithIdMe),
                icon: Image.asset(
                  'assets/idme_logo.png',
                  height: 24.0,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.verified_user,
                        size: 24, color: Colors.blue);
                  },
                ),
                text: 'Sign in with ID.me',
              ),
              SizedBox(height: 16),
              _buildSignInButton(
                onPressed: _isLoading ? null : () => _showEmailPasswordDialog(),
                icon: Icon(Icons.login, size: 24, color: Colors.green),
                text: 'App Store Review Access',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmailPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('App Store Reviewer Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Login'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleSignIn(signInWithEmailPassword);
              },
            ),
          ],
        );
      },
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
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
