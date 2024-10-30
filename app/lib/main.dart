import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'app_state.dart';
import 'scuttlebutt_app.dart';
import 'login_screen.dart';
import 'zone_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (const bool.fromEnvironment('USE_FIREBASE_EMU')) {
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Scuttle',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  Future<bool> _checkFirstInstall() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstInstall = prefs.getBool('is_first_install') ?? true;
    if (isFirstInstall) {
      await prefs.setBool('is_first_install', false);
    }
    return isFirstInstall;
  }

  Future<bool> _checkZoneAcknowledged() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('zone_acknowledged') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkFirstInstall(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          bool isFirstInstall = snapshot.data ?? true;

          if (isFirstInstall) {
            return LoginScreen();
          } else {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  User? user = snapshot.data;
                  if (user == null) {
                    return LoginScreen();
                  }
                  return FutureBuilder<void>(
                    future: _initializeUserData(context, user),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return FutureBuilder<bool>(
                          future: _checkZoneAcknowledged(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              bool zoneAcknowledged = snapshot.data ?? false;
                              final appState =
                                  Provider.of<AppState>(context, listen: false);
                              if (!zoneAcknowledged || appState.isNewUser) {
                                return ZoneSelectionScreen(
                                    isInitialSetup: true);
                              }
                              return ScuttleHomePage();
                            }
                            return Scaffold(
                                body:
                                    Center(child: CircularProgressIndicator()));
                          },
                        );
                      }
                      return Scaffold(
                          body: Center(child: CircularProgressIndicator()));
                    },
                  );
                }
                return Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              },
            );
          }
        }
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Future<void> _initializeUserData(BuildContext context, User user) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.initializeUser(user.uid);

    // Check if the user has points, if not, calculate them
    if (appState.userPoints == 0) {
      await appState.calculateAndSetInitialPoints();
    }
  }
}
