import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../models/models.dart';

class WhatsAppService {
  /// Launches WhatsApp using a backend-generated URL for student absence.
  static Future<void> sendAbsenceMessage({
    required String classId,
    required String studentId,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    // Fetch formatted message and URL from backend to ensure consistent business logic
    final json = await ApiClient.get('/attendance/$classId/$dateStr/$studentId/whatsapp');
    final data = AbsenteeWhatsAppInfo.fromJson(json);
    
    final urlStr = data.whatsappUrl;
    if (urlStr == null || urlStr.isEmpty) {
      throw Exception('Backend failed to generate WhatsApp URL');
    }

    final url = Uri.parse(urlStr);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp');
    }
  }
}
