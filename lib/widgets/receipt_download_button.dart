import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/receipt_provider.dart';

class ReceiptDownloadButton extends StatelessWidget {
  final String studentId;
  final int installmentNo;
  final VoidCallback? onSuccess;

  const ReceiptDownloadButton({
    super.key,
    required this.studentId,
    required this.installmentNo,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isDownloading;

        return ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () => _handleDownload(context, provider),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A), // Deep Blue requested
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            disabledBackgroundColor: const Color(0xFF1E3A8A).withOpacity(0.6),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download_rounded, size: 20),
          label: Text(
            isLoading ? "Downloading..." : "Download Receipt",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDownload(BuildContext context, ReceiptProvider provider) async {
    final success = await provider.downloadReceipt(
      studentId: studentId,
      installmentNo: installmentNo,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("Receipt downloaded successfully!"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      onSuccess?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(provider.error ?? "Failed to download receipt")),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: "RETRY",
            textColor: Colors.white,
            onPressed: () => _handleDownload(context, provider),
          ),
        ),
      );
    }
  }
}
