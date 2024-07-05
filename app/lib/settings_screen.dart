import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white), // Set text color to white
        ),
        backgroundColor: Colors.blue[800],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Log Out'),
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
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
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

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
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
