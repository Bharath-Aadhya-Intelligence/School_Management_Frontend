import 'package:flutter/material.dart';
import '../services/receipt_service.dart';

class ReceiptProvider with ChangeNotifier {
  final ReceiptService _receiptService = ReceiptService();

  bool _isDownloading = false;
  String? _error;
  String? _lastDownloadedPath;

  bool get isDownloading => _isDownloading;
  String? get error => _error;
  String? get lastDownloadedPath => _lastDownloadedPath;

  /// Downloads the receipt for a given student and installment number.
  /// 
  /// Automatically handles state notifications for loading and errors.
  Future<bool> downloadReceipt({
    required String studentId,
    required int installmentNo,
  }) async {
    _isDownloading = true;
    _error = null;
    notifyListeners();

    try {
      _lastDownloadedPath = await _receiptService.downloadReceipt(studentId, installmentNo);
      _isDownloading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isDownloading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clears the current error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
