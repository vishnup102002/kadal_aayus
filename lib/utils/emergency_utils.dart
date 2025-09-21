import 'package:url_launcher/url_launcher.dart';

// This function will trigger the device's SMS app
Future<void> sendSOS(String locationText) async {
  // Replace with the actual emergency contact number
  const String emergencyNumber = '+91 79026 35297';
  final Uri smsUri = Uri(
    scheme: 'sms',
    path: emergencyNumber,
    queryParameters: {'body': 'SOS! I need help. My last known location: $locationText'},
  );

  try {
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      // Handle the case where SMS cannot be launched
      print('Could not launch SMS. Please send manually.');
    }
  } catch (e) {
    print('Failed to send SOS: $e');
  }
}
