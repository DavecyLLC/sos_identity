import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          _termsText,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}

const String _termsText = '''
SOS Identity – Terms & Conditions

Last updated: January 2025
Welcome to SOS Identity, a personal identification and emergency-assistance application created by Davecy LLC.
By using this application, you agree to the following terms:

1. Purpose of the Application
SOS Identity is designed to help users store personal identification information locally on their device and to assist with emergency communication by preparing messages for the user to send manually.
SOS Identity does not provide professional safety, medical, or emergency response services.

2. No Liability – No Guarantees
Davecy LLC makes no guarantees regarding:
Delivery, timing, or success of SOS messages
Accuracy of GPS location information
Availability of network connectivity
Security of the user's device, operating system, or third-party apps
Whether emergency contacts receive or act upon notifications
The user’s personal safety during any emergency
By using SOS Identity, you agree that Davecy LLC is not responsible for any harm, loss, injury, or damages resulting from the use or failure of the application.

3. Data Storage & Security
SOS Identity stores data locally on the user’s device.
No data is uploaded to any server owned by Davecy LLC.
The app uses:
Local device storage
Optional encrypted secure storage
Optional PIN lock
However:
The overall security of your data depends primarily on your device’s operating system (Android / iOS), passcode, biometric lock, and the user’s personal practices.
Davecy LLC cannot guarantee:
Protection against device theft
Protection from malware, rooting, jailbreaking, or OS vulnerabilities
Recovery of lost or deleted data
You are responsible for maintaining the security of your device.

4. No Automatic Actions
SOS Identity does not automatically send SMS messages, make calls, or share your location.
All outgoing emergency messages require manual confirmation by the user in the phone’s SMS app.

5. User Responsibility
By using this app, the user agrees that:
They are responsible for entering correct information
They determine who receives SOS messages
They use the application appropriately and safely
They understand the application is supportive, not life-saving

6. Not a Substitute for Emergency Services
SOS Identity is not a replacement for:
Calling 911
Emergency medical services
Law enforcement
Professional monitoring systems
If you are in immediate danger, call your local emergency number.

7. Limitation of Liability
To the fullest extent permitted by law:
Davecy LLC, its owners, developers, and affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from or related to the app.

8. Acceptance of Terms
By using SOS Identity, you acknowledge that:
You have read and understood these terms
You agree to all conditions
You release Davecy LLC from liability related to app usage
If you do not agree, discontinue use of the application.
''';
