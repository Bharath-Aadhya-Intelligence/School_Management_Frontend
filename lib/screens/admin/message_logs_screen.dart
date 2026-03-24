import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../theme/app_theme.dart';

class MessageLogsScreen extends StatefulWidget {
  const MessageLogsScreen({super.key});

  @override
  State<MessageLogsScreen> createState() => _MessageLogsScreenState();
}

class _MessageLogsScreenState extends State<MessageLogsScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/logs/messages?limit=100');
      if (!mounted) return;
      setState(() {
        _logs = data as List;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAllLogs() async {
    setState(() => _isLoading = true);
    try {
      await ApiClient.delete('/logs/messages');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All logs cleared successfully.'),
          backgroundColor: AppTheme.paidGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchLogs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text(
          'This will permanently delete all WhatsApp message logs. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAllLogs();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.unpaidRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('WhatsApp Message Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.unpaidRed),
            onPressed: _logs.isEmpty ? null : _showDeleteConfirmation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: AppTheme.unpaidRed),
                      const SizedBox(height: 16),
                      Text('Error loading logs: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchLogs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _logs.isEmpty
                  ? const Center(
                      child: Text('No message logs found.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final statusStr = (log['status'] ?? 'unknown').toString().toLowerCase();
                        final isFailed = statusStr == 'failed' || statusStr == 'undelivered';
                        final isWaiting = statusStr == 'queued' || statusStr == 'sent';
                        
                        Color statusColor;
                        IconData statusIcon;
                        
                        if (isFailed) {
                          statusColor = AppTheme.unpaidRed;
                          statusIcon = Icons.error_outline_rounded;
                        } else if (isWaiting) {
                          statusColor = AppTheme.warningAmber;
                          statusIcon = Icons.schedule_rounded;
                        } else {
                          statusColor = AppTheme.paidGreen;
                          statusIcon = Icons.check_circle_outline_rounded;
                        }

                        final dt = DateTime.tryParse(log['timestamp'] ?? '');
                        final timeStr = dt != null
                            ? DateFormat('MMM d, h:mm a').format(dt.toLocal())
                            : 'Unknown Time';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppTheme.darkBorder
                                  : AppTheme.borderLight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          log['student_name'] ?? 'Unknown',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            statusStr.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${log['contact']} • $timeStr',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary),
                                    ),
                                    if (isFailed && log['error'] != null) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.unpaidRed.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.unpaidRed.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.unpaidRed),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                log['error'],
                                                style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.unpaidRed),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
