import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_client.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class MessageLogsScreen extends StatefulWidget {
  const MessageLogsScreen({super.key});

  @override
  State<MessageLogsScreen> createState() => _MessageLogsScreenState();
}

class _MessageLogsScreenState extends State<MessageLogsScreen> {
  List<dynamic> _logs = [];
  List<dynamic> _classes = [];
  bool _isLoading = true;
  String? _error;

  // Filters
  String? _selectedClassId; // null means 'All'
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAdmin) {
      await _fetchClasses();
    }
    await _fetchLogs();
  }

  Future<void> _fetchClasses() async {
    try {
      final data = await ApiClient.get('/classes/');
      if (!mounted) return;
      setState(() {
        _classes = data as List;
      });
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String query = '?limit=100';
      if (_selectedClassId != null) {
        query += '&class_id=$_selectedClassId';
      }
      if (_startDate != null) {
        query += '&date_from=${DateFormat('yyyy-MM-dd').format(_startDate!)}';
      }
      if (_endDate != null) {
        query += '&date_to=${DateFormat('yyyy-MM-dd').format(_endDate!)}';
      }

      final data = await ApiClient.get('/logs/messages$query');
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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.staffPurple,
              primary: AppTheme.staffPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchLogs();
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedClassId = null;
      _startDate = null;
      _endDate = null;
    });
    _fetchLogs();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('WhatsApp Logs'),
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
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.borderLight,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (auth.isAdmin)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppTheme.darkBorder : AppTheme.borderLight,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              hint: const Text('All Classes'),
                              value: _selectedClassId,
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Classes'),
                                ),
                                ..._classes.map((c) => DropdownMenuItem(
                                      value: c['class_id'],
                                      child: Text(c['name']),
                                    )),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedClassId = val);
                                _fetchLogs();
                              },
                            ),
                          ),
                        ),
                      ),
                    if (auth.isAdmin) const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppTheme.darkBorder : AppTheme.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _startDate == null
                                      ? 'Select Date'
                                      : _endDate == _startDate
                                          ? DateFormat('MMM d').format(_startDate!)
                                          : '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_selectedClassId != null || _startDate != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.unpaidRed),
                        onPressed: _resetFilters,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : _logs.isEmpty
                        ? const Center(child: Text('No message logs found.'))
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
                                    color: isDark ? AppTheme.darkBorder : AppTheme.borderLight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withValues(alpha: 0.08),
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
                                        color: statusColor.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(statusIcon, color: statusColor, size: 22),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  log['student_name'] ?? 'Unknown',
                                                  style: GoogleFonts.inter(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 16),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.1),
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
                                          Row(
                                            children: [
                                              Text(
                                                '${log['contact']} • ',
                                                style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textSecondary),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.staffPurple.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  log['class_name'] ?? 'Other',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.staffPurple,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            timeStr,
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary),
                                          ),
                                          if (isFailed && log['error'] != null) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.unpaidRed.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppTheme.unpaidRed.withValues(alpha: 0.2)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.unpaidRed),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchLogs, child: const Text('Retry')),
        ],
      ),
    );
  }
}

