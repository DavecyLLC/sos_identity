import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static Future<void> sendSms({
    required String phone,
    required String message,
  }) async {
    final encodedMessage = Uri.encodeComponent(message);

    final Uri uri = Platform.isIOS
        ? Uri.parse('sms:$phone&body=$encodedMessage')
        : Uri.parse('sms:$phone?body=$encodedMessage');

    if (!await canLaunchUrl(uri)) {
      throw Exception('Could not launch SMS app');
    }

    await launchUrl(uri);
  }
}
