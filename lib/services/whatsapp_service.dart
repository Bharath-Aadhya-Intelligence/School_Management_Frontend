import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class WhatsAppService {
  /// Launches WhatsApp with a pre-filled message for student absence.
  /// 
  /// [contact] The phone number (including country code, e.g., '919876543210').
  /// [studentName] The name of the student.
  /// [rollNo] The roll number of the student.
  /// [date] The date of absence.
  static Future<void> sendAbsenceMessage({
    required String contact,
    required String studentName,
    String? rollNo,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('dd-MM-yyyy').format(date);
    final rollStr = (rollNo != null && rollNo.isNotEmpty) ? ' (Roll No: $rollNo)' : '';
    
    final message = 'Dear Parent, your child $studentName$rollStr was absent from school today ($dateStr). Regards, School Management.';
    
    // Clean contact number: remove spaces, dashes, etc.
    String cleanContact = contact.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Ensure it has a country code. Defaulting to 91 (India) if it's 10 digits.
    if (cleanContact.length == 10) {
      cleanContact = '91$cleanContact';
    }

    final url = Uri.parse('https://wa.me/$cleanContact?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp for $cleanContact');
    }
  }
}
