import 'package:flutter/material.dart';

class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({Key? key}) : super(key: key);

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
              'Community Guidelines',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildGuideline('No PII (Personally Identifiable Information).'),
            _buildGuideline('Don\'t troll or be disrespectful to others.'),
            _buildGuideline('No hate speech or discriminatory content.'),
            _buildGuideline(
                'No posting links to malicious sites or spreading malware.'),
            _buildGuideline('No obscene or explicit content.'),
            _buildGuideline('No promotion or glorification of violence.'),
            _buildGuideline(
                'No illegal activities or content that violates laws.'),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }
}
