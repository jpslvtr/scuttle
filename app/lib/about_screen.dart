import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Scuttle',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildParagraph(
              'Scuttle is an anonymous feed-based social app for service members to engage with other service members near them. As a Navy veteran, I initially focused on the Navy for this version.',
            ),
            SizedBox(height: 16),
            Text(
              'There are eight "zones," each with a generous radius:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• Norfolk\n• San Diego\n• Jacksonville\n• Pensacola\n• PNW\n• Japan\n• Hawaii\n• DMV',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            _buildParagraph(
              'I initially considered setting zones at the command level, but decided against it due to OPSEC. All users\' military status is verified through ID.me.',
            ),
            SizedBox(height: 16),
            _buildParagraph(
              'Blind exists for companies, Fizz for colleges, and while Yik Yak is no longer as widely used, Scuttle aims to fill a similar niche for service members. Whether you\'re temporarily on TDY and don\'t know anyone, or you want to connect with service members near you, Scuttle is here to help.',
            ),
            SizedBox(height: 16),
            _buildParagraph(
              'The main difference between our "All Navy" feed and the Navy subreddit is that everyone on Scuttle is a verified military member.',
            ),
            SizedBox(height: 16),
            _buildParagraph(
              'The app is still in development and may have some bugs. Feedback and comments are welcome. Please feel free to contact jpslvtr@gmail.com.\n',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 18),
    );
  }
}
