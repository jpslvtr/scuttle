import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'login_screen.dart';
import 'zone_selection_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';
import 'guidelines_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return SafeArea(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildSectionHeader('App'),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Guidelines'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GuidelinesScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy policy'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
              );
            },
          ),
          _buildSectionHeader('Account'),
          ListTile(
            leading: Icon(Icons.location_city),
            title: Text(appState.command == null ? 'Set Zone' : 'Current Zone'),
            subtitle: Text(appState.command ?? 'Not set'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        ZoneSelectionScreen(isInitialSetup: false)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Log Out'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Provider.of<AppState>(context, listen: false).clearUserData();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              _showDeleteAccountConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await Provider.of<AppState>(context, listen: false)
                      .deleteAccount();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Account deleted successfully')),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  print('Error deleting account: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
