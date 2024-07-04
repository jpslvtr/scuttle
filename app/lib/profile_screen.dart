import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Text('Profile screen - To be implemented'),
      ),
    );
  }
}
