import 'dart:io';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../api/api_client.dart';

class ReceiptService {
  /// Downloads a fee receipt PDF for a specific student and installment.
  /// 
  /// Returns the path to the saved file on success.
  Future<String> downloadReceipt(String studentId, int installmentNo) async {
    try {
      // 1. Request Storage Permissions (Android 10 and below)
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted && !await Permission.manageExternalStorage.isGranted) {
          throw Exception('Storage permission is required to download receipts');
        }
      }

      // 2. Fetch PDF from API
      // Endpoint: GET /exports/receipt/{student_id}/{installment_no}
      final path = '/exports/receipt/$studentId/$installmentNo';
      final response = await ApiClient.getRaw(path);

      if (response.statusCode != 200) {
        throw Exception('Failed to download receipt (Status: ${response.statusCode})');
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw Exception('Received empty file from server');
      }

      // 3. Determine Save Directory
      Directory? directory;
      if (Platform.isAndroid) {
        // Use Downloads directory on Android
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        // Use Documents directory on iOS
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access local storage');
      }

      // 4. Create File Path
      final fileName = 'receipt_${studentId}_$installmentNo.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // 5. Write File
      await file.writeAsBytes(bytes, flush: true);

      // 6. Open File Automatically
      final result = await OpenFilePlus.open(filePath);
      if (result.type != ResultType.done) {
        // If it failed to open but saved successfully, we still return the path
        print('Warning: File saved but failed to open automatically: ${result.message}');
      }

      return filePath;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }
}
