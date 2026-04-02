import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/sort_utils.dart';
import 'package:intl/intl.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/bulk_notification_sheet.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String classId;

  const AttendanceHistoryScreen({super.key, required this.classId});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;
  int _totalPresent = 0;
  int _totalAbsent = 0;
  Map<String, String> _studentContacts = {};

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _fetchAttendanceHistory();
  }

  @override
  void didUpdateWidget(covariant AttendanceHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _fetchStudents();
      _fetchAttendanceHistory();
    }
  }

  Future<void> _fetchAttendanceHistory() async {
    if (widget.classId.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final json = await ApiClient.get('/attendance/${widget.classId}/$dateStr');

      if (!mounted) return;

      final history = AttendanceHistory.fromJson(json);

      setState(() {
        _attendanceRecords = history.records;
        _attendanceRecords.sort((a, b) => SortUtils.compareNatural(a.rollNo ?? '', b.rollNo ?? ''));
        _totalPresent = history.totalPresent;
        _totalAbsent = history.totalAbsent;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchStudents() async {
    if (widget.classId.isEmpty) return;
    try {
      final data = await ApiClient.get('/students/${widget.classId}');
      final students = (data as List).map((e) => StudentModel.fromJson(e)).toList();
      if (!mounted) return;
      setState(() {
        _studentContacts = {for (var s in students) s.studentId: s.contact};
      });
    } catch (e) {
      debugPrint('Error fetching students: $e');
    }
  }

  Future<void> _showBulkNotificationSheet() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final json = await ApiClient.get('/attendance/${widget.classId}/$dateStr/whatsapp-data');
      final data = WhatsAppDataResponse.fromJson(json);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (data.absentees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No absentees to notify.')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BulkNotificationSheet(
          data: data,
          date: _selectedDate,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.staffPurple,
              onPrimary: Colors.white,
              onSurface: AppTheme.lightText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchAttendanceHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.classId.isEmpty) {
      return Center(
        child: Text(
          'No class assigned to view history.',
          style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        // Date Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                  bottom: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkBorder
                          : AppTheme.borderLight))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded,
                    color: AppTheme.staffPurple),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
        ),

        // Content Area
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 48, color: AppTheme.unpaidRed),
                              const SizedBox(height: 16),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchAttendanceHistory,
                                child: const Text('Retry'),
                              ),
                            ],
                          )),
                    )
                  : _attendanceRecords.isEmpty
                      ? Center(
                          child: Text(
                            'No attendance records found for this date.',
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary),
                          ),
                        )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(
                            children: [
                              _StatChip(
                                label: 'Present',
                                value: '$_totalPresent',
                                color: AppTheme.paidGreen,
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                label: 'Absent',
                                value: '$_totalAbsent',
                                color: AppTheme.unpaidRed,
                              ),
                              if (_totalAbsent > 0) ...[
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _showBulkNotificationSheet,
                                  icon: const Icon(Icons.chat_rounded, size: 20),
                                  label: const Text('Notify All'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.paidGreen,
                                    textStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _attendanceRecords.length,
                            itemBuilder: (context, index) {
                              final record = _attendanceRecords[index];
                              final status = record.status;
                              final studentName = record.studentName ?? 'Unknown Student';
                              final rollNo = record.rollNo ?? '-';
                              final isPresent = status == 'present' || status == 'p';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppTheme.darkBorder
                                        : AppTheme.borderLight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isPresent
                                          ? AppTheme.paidGreen.withValues(alpha: 0.12)
                                          : AppTheme.unpaidRed.withValues(alpha: 0.12),
                                      child: Text(
                                        rollNo.isNotEmpty ? rollNo : '?',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isPresent
                                              ? AppTheme.paidGreen
                                              : AppTheme.unpaidRed,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        studentName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPresent
                                            ? AppTheme.paidGreen.withValues(alpha: 0.15)
                                            : AppTheme.unpaidRed
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isPresent ? 'Present' : 'Absent',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isPresent
                                              ? AppTheme.paidGreen
                                              : AppTheme.unpaidRed,
                                        ),
                                      ),
                                    ),
                                    if (!isPresent) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.chat_rounded,
                                          color: AppTheme.paidGreen,
                                          size: 24,
                                        ),
                                        onPressed: () async {
                                          final contact = record.contact ?? _studentContacts[record.studentId];
                                          if (contact == null || contact.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Contact Number Not Found')),
                                            );
                                            return;
                                          }
                                          try {
                                            await WhatsAppService.sendAbsenceMessage(
                                              contact: contact,
                                              studentName: studentName,
                                              rollNo: rollNo,
                                              date: _selectedDate,
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: ${e.toString()}')),
                                            );
                                          }
                                        },
                                        tooltip: 'Notify via WhatsApp',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value ',
            style: GoogleFonts.inter(
                color: color, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}
