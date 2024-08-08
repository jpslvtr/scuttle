import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

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
              'PRIVACY POLICY',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildParagraph(
              'Welcome to Scuttle. We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our app.',
            ),
            SizedBox(height: 16),
            _buildSection('INFORMATION WE COLLECT',
                'We may collect the following types of information: location data, user-generated content, usage data and app activity, and information from third-party services.'),
            _buildSection('HOW WE USE YOUR INFORMATION',
                'We use your information to provide and improve our services, personalize your experience, facilitate social features and sharing, communicate with you about the app and your account, and ensure the security and functionality of our app.'),
            _buildSection('DATA SHARING AND DISCLOSURE',
                'We may share your information with other users, based on your privacy settings, and with third-party service providers who assist in our operations.'),
            _buildSection('YOUR CHOICES AND RIGHTS',
                'You can access, update, or delete your personal information, adjust your privacy settings within the app, and opt-out of certain data collection or use.'),
            _buildSection('DATA SECURITY',
                'We implement appropriate technical and organizational measures to protect your data.'),
            _buildSection('CHANGES TO THIS POLICY',
                'We may update this policy from time to time. We will notify you of any significant changes.'),
            _buildSection('CONTACT US',
                'If you have any questions about this privacy policy, please contact us at jpslvtr@gmail.com.\n'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        _buildParagraph(content),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 18),
    );
  }
}
