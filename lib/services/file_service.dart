import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../api/api_client.dart';

class FileService {
  static Future<void> downloadAndShare(String path, String fileName) async {
    try {
      final response = await ApiClient.getRaw(path);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: fileName,
        );
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  static Future<void> clearTemporaryFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final contents = tempDir.listSync(recursive: true);
        for (var fileOrDir in contents) {
          if (fileOrDir is File) {
            await fileOrDir.delete();
          } else if (fileOrDir is Directory) {
            await fileOrDir.delete(recursive: true);
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to clear local data: $e');
    }
  }
}
