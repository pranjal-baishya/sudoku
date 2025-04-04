import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), elevation: 1),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Sudoku Game',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: 04/04/2025',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text(
              'Pranjal Baishya (Developer) operates the Sudoku Game mobile application.',
            ),
            SizedBox(height: 16),
            Text(
              'This page informs you of our policies regarding the collection, use, and disclosure of personal data when you use our Service and the choices you have associated with that data. Our Privacy Policy for Sudoku Game is managed with the help of the Privacy Policy Generator.',
            ),
            SizedBox(height: 16),
            Text(
              'Information Collection and Use',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Our Sudoku Game is designed to be a simple, offline experience. We do not collect any Personally Identifiable Information (PII) from you while you use the application.',
            ),
            SizedBox(height: 16),
            Text(
              'Locally Stored Data (Preferences)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'To enhance your gaming experience, the app utilizes local storage on your device (specifically using Flutter\'s "shared_preferences" package) to save:',
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0),
              child: Text(
                '• Your current game progress (puzzle state, selected cells, notes)\n' +
                    '• Game settings (such as difficulty level, timer state, theme preference)\n' +
                    '• Statistics like mistakes made or hints used.',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This data is stored solely on your device and is never transmitted off your device by the application. It is used only to allow you to resume your game and maintain your settings between sessions.',
            ),
            SizedBox(height: 16),
            Text(
              'Permissions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'The Sudoku Game application does not require any special device permissions (like location, contacts, camera, etc.) to function.',
            ),
            SizedBox(height: 16),
            Text(
              'Children\'s Privacy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Our Service does not address anyone under the age of 13 ("Children"). We do not knowingly collect personally identifiable information from anyone under the age of 13. Since we do not collect any PII, we inherently do not collect information from children.',
            ),
            SizedBox(height: 16),
            Text(
              'Changes to This Privacy Policy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page within the app. You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.',
            ),
            SizedBox(height: 16),
            Text(
              'Contact Us',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'If you have any questions about this Privacy Policy, please contact us:',
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0),
              child: Text('• By email: pranjalbaishya809@gmail.com'),
            ),
          ],
        ),
      ),
    );
  }
}
