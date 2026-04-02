import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class BulkNotificationSheet extends StatefulWidget {
  final WhatsAppDataResponse data;
  final DateTime date;

  const BulkNotificationSheet({super.key, required this.data, required this.date});

  @override
  State<BulkNotificationSheet> createState() => _BulkNotificationSheetState();
}

class _BulkNotificationSheetState extends State<BulkNotificationSheet> {
  final Set<String> _notifiedStudents = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.chat_rounded, color: AppTheme.paidGreen, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bulk Notify Absentees',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${widget.data.absentees.length} students to be notified',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.data.absentees.length,
              itemBuilder: (context, index) {
                final student = widget.data.absentees[index];
                final isNotified = _notifiedStudents.contains(student.studentName);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isNotified ? AppTheme.paidGreen.withValues(alpha: 0.3) : AppTheme.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.studentName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isNotified ? AppTheme.textSecondary : null,
                                decoration: isNotified ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              'Parent: ${student.parentName} (${student.contact})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final urlStr = student.whatsappUrl;
                          if (urlStr == null || urlStr.isEmpty) return;

                          try {
                            final url = Uri.parse(urlStr);
                            
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                              if (mounted) {
                                setState(() {
                                  _notifiedStudents.add(student.studentName);
                                });
                              }
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isNotified ? AppTheme.lightBg : AppTheme.paidGreen,
                          foregroundColor: isNotified ? AppTheme.textSecondary : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(isNotified ? 'Resend' : 'Send'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
